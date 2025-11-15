#!/usr/bin/env python3
"""
Maya1 Text-to-Speech Generator
Usage: python maya_tts.py <input_file> [output_file] --voice "Voice description"

Example:
  python maya_tts.py input.txt --voice "Female, in her 30s with an American accent, energetic"
  python maya_tts.py input.txt output.wav --voice "Male, 40s, British accent"
"""

import argparse
import os
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from snac import SNAC
import soundfile as sf
import numpy as np

# Maya1 special token IDs
CODE_START_TOKEN_ID = 128257
CODE_END_TOKEN_ID = 128258
CODE_TOKEN_OFFSET = 128266
SNAC_MIN_ID = 128266
SNAC_MAX_ID = 156937
SNAC_TOKENS_PER_FRAME = 7

SOH_ID = 128259
EOH_ID = 128260
SOA_ID = 128261
BOS_ID = 128000
TEXT_EOT_ID = 128009


def build_prompt(tokenizer, description: str, text: str) -> str:
    """Build formatted prompt for Maya1."""
    soh_token = tokenizer.decode([SOH_ID])
    eoh_token = tokenizer.decode([EOH_ID])
    soa_token = tokenizer.decode([SOA_ID])
    sos_token = tokenizer.decode([CODE_START_TOKEN_ID])
    eot_token = tokenizer.decode([TEXT_EOT_ID])
    bos_token = tokenizer.bos_token
    
    formatted_text = f'<description="{description}"> {text}'
    
    prompt = (
        soh_token + bos_token + formatted_text + eot_token +
        eoh_token + soa_token + sos_token
    )
    
    return prompt


def extract_snac_codes(token_ids: list) -> list:
    """Extract SNAC codes from generated tokens."""
    try:
        eos_idx = token_ids.index(CODE_END_TOKEN_ID)
    except ValueError:
        eos_idx = len(token_ids)
    
    snac_codes = [
        token_id for token_id in token_ids[:eos_idx]
        if SNAC_MIN_ID <= token_id <= SNAC_MAX_ID
    ]
    
    return snac_codes


def unpack_snac_from_7(snac_tokens: list) -> list:
    """Unpack 7-token SNAC frames to 3 hierarchical levels."""
    if snac_tokens and snac_tokens[-1] == CODE_END_TOKEN_ID:
        snac_tokens = snac_tokens[:-1]
    
    frames = len(snac_tokens) // SNAC_TOKENS_PER_FRAME
    snac_tokens = snac_tokens[:frames * SNAC_TOKENS_PER_FRAME]
    
    if frames == 0:
        return [[], [], []]
    
    l1, l2, l3 = [], [], []
    
    for i in range(frames):
        slots = snac_tokens[i*7:(i+1)*7]
        l1.append((slots[0] - CODE_TOKEN_OFFSET) % 4096)
        l2.extend([
            (slots[1] - CODE_TOKEN_OFFSET) % 4096,
            (slots[4] - CODE_TOKEN_OFFSET) % 4096,
        ])
        l3.extend([
            (slots[2] - CODE_TOKEN_OFFSET) % 4096,
            (slots[3] - CODE_TOKEN_OFFSET) % 4096,
            (slots[5] - CODE_TOKEN_OFFSET) % 4096,
            (slots[6] - CODE_TOKEN_OFFSET) % 4096,
        ])
    
    return [l1, l2, l3]


def main():
    parser = argparse.ArgumentParser(
        description="Generate expressive speech using Maya1 TTS model",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python maya_tts.py input.txt
  python maya_tts.py input.txt --voice "Male, 40s, British accent, warm and conversational"
  python maya_tts.py input.txt custom_output.wav --voice "Female, energetic event host, clear diction"
  
Emotion tags (use inline in text):
  <laugh> <sigh> <whisper> <angry> <giggle> <chuckle> <gasp> <cry> <laugh_harder> <snort>
        """
    )
    parser.add_argument("input_file", help="Text file to convert to speech")
    parser.add_argument("output_file", nargs='?', default=None, 
                        help="Output audio file (default: same as input with .wav extension)")
    parser.add_argument("--voice", 
                        default="Approachable, warm, and eager young woman in her early 20s.",
                        help="Voice description (natural language)")
    parser.add_argument("--model", default="maya-research/maya1",
                        help="Model to use (default: maya-research/maya1, or path to fine-tuned model)")
    parser.add_argument("--temperature", type=float, default=0.4,
                        help="Sampling temperature (default: 0.4)")
    
    args = parser.parse_args()
    
    # Load voice description from fine-tuned model if available
    if args.model != "maya-research/maya1" and os.path.exists(f"{args.model}/voice_description.txt"):
        with open(f"{args.model}/voice_description.txt", 'r') as f:
            default_voice = f.read().strip()
            if args.voice == "Approachable, warm, and eager young woman in her early 20s.":
                args.voice = default_voice
                print(f"Using fine-tuned voice: {default_voice}")
    
    # Auto-generate output filename if not provided
    if args.output_file is None:
        base_name = os.path.splitext(args.input_file)[0]
        args.output_file = f"{base_name}.wav"
    
    # Read entire input text without truncation
    print(f"\n[1/4] Reading input text...")
    with open(args.input_file, 'r', encoding='utf-8') as f:
        text = f.read()  # Read all content without stripping
    
    text_length = len(text)
    word_count = len(text.split())
    print(f"Text loaded: {text_length} characters, {word_count} words")
    print(f"Preview: {text[:150]}{'...' if len(text) > 150 else ''}")
    
    # Load Maya1 model
    print(f"\n[2/4] Loading Maya1 model...")
    print(f"Model: {args.model}")
    model = AutoModelForCausalLM.from_pretrained(
        args.model, 
        dtype=torch.bfloat16, 
        device_map="auto",
        trust_remote_code=True
    )
    tokenizer = AutoTokenizer.from_pretrained(
        args.model,
        trust_remote_code=True
    )
    print(f"Model loaded: {len(tokenizer)} tokens in vocabulary")
    
    # Load SNAC audio decoder (24kHz)
    print(f"\n[3/4] Loading SNAC audio decoder...")
    snac_model = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval()
    if torch.cuda.is_available():
        snac_model = snac_model.to("cuda")
    print("SNAC decoder loaded")
    
    # Generate speech
    print(f"\n[4/4] Generating speech...")
    print(f"Voice: {args.voice}")
    
    # Create prompt with proper formatting
    prompt = build_prompt(tokenizer, args.voice, text)
    
    # Generate emotional speech
    inputs = tokenizer(prompt, return_tensors="pt", truncation=False)
    input_token_count = inputs['input_ids'].shape[1]
    print(f"Input tokens: {input_token_count}")
    
    # Calculate estimated output tokens needed (roughly 7 SNAC tokens per 0.042s of audio)
    # Assume ~150 words per minute speaking rate = 2.5 words/sec
    # So word_count / 2.5 = seconds, * 7 / 0.042 = tokens needed
    estimated_duration_sec = word_count / 2.5
    estimated_tokens_needed = int(estimated_duration_sec / 0.042 * 7) + 500  # Add buffer
    max_tokens = max(estimated_tokens_needed, 4096)  # At least 4096 tokens
    
    print(f"Estimated speech duration: ~{estimated_duration_sec:.1f}s")
    print(f"Using max_new_tokens: {max_tokens}")
    
    if torch.cuda.is_available():
        inputs = {k: v.to("cuda") for k, v in inputs.items()}
    
    with torch.inference_mode():
        outputs = model.generate(
            **inputs, 
            max_new_tokens=max_tokens,  # Dynamic based on input length
            min_new_tokens=28,  # At least 4 SNAC frames
            temperature=args.temperature, 
            top_p=0.9, 
            repetition_penalty=1.1,
            do_sample=True,
            eos_token_id=CODE_END_TOKEN_ID,
            pad_token_id=tokenizer.pad_token_id,
        )
    
    # Extract generated tokens
    generated_ids = outputs[0, inputs['input_ids'].shape[1]:].tolist()
    print(f"Generated {len(generated_ids)} tokens")
    
    # Extract SNAC audio tokens
    snac_tokens = extract_snac_codes(generated_ids)
    print(f"Extracted {len(snac_tokens)} SNAC tokens")
    
    if len(snac_tokens) < 7:
        print("Error: Not enough SNAC tokens generated")
        return
    
    # Unpack SNAC tokens to 3 hierarchical levels
    levels = unpack_snac_from_7(snac_tokens)
    frames = len(levels[0])
    
    print(f"Unpacked to {frames} frames (L1: {len(levels[0])}, L2: {len(levels[1])}, L3: {len(levels[2])})")
    
    # Convert to tensors
    device = "cuda" if torch.cuda.is_available() else "cpu"
    codes_tensor = [
        torch.tensor(level, dtype=torch.long, device=device).unsqueeze(0)
        for level in levels
    ]
    
    # Generate final audio with SNAC decoder
    print(f"\nDecoding to audio...")
    with torch.inference_mode():
        z_q = snac_model.quantizer.from_codes(codes_tensor)
        audio = snac_model.decoder(z_q)[0, 0].cpu().numpy()
    
    # Don't trim audio - keep full output
    duration_sec = len(audio) / 24000
    print(f"Audio: {len(audio)} samples ({duration_sec:.2f}s @ 24kHz)")
    
    # Save audio
    sf.write(args.output_file, audio, 24000)
    print(f"\n✓ Voice generated: {args.output_file}")
    print(f"  Input: {text_length} characters ({word_count} words)")
    print(f"  Output: {duration_sec:.2f}s audio")


if __name__ == "__main__":
    main()

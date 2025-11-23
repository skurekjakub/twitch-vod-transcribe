# 2. Episode Index & Glossary

## 2.1. Primary Subjects & Themes

- **4-bit floating-point training for large language models** - The main technical achievement and focus of the video
- **Evolution of precision in deep learning training** - Historical progression from FP32 → FP16 → FP8 → FP4
- **Mixed-precision training frameworks** - The practical reality of combining different bit widths in neural network training
- **Quantization techniques and their trade-offs** - Methods for reducing numerical precision while maintaining model quality
- **Nvidia Tensor Cores architecture** - The hardware foundation enabling efficient mixed-precision matrix operations
- **Microscaling (MX) data formats** - Industry-standard low-precision numeric formats designed for quantization
- **Cost economics of LLM training** - The financial drivers motivating precision reduction
- **Matrix multiplication optimization** - The primary computational target for quantization efforts
- **Gradient quantization challenges** - Technical obstacles in reducing precision of gradients during backpropagation
- **Quantization-aware training vs. fully quantized training** - Comparison of different training methodologies

## 2.2. Glossary of People, Places & Passing Mentions

### Organizations & Companies

**DeepSeek** - Chinese AI research lab that pioneered 8-bit (FP8) training in production with their DeepSeek V3 model in 2024, achieving 10x cost reductions compared to Western competitors and establishing a new industry trend. Mentioned as potentially having acquired restricted H100 GPUs through indirect channels despite US-China export controls.

**Qwen** - Chinese AI research lab mentioned alongside DeepSeek as achieving significant cost reductions in LLM training, bringing costs down to the millions of dollars.

**Google Brain** - Google's AI research division that unlocked 16-bit training in 2018 with their BFloat16 (BF16) format, which modified the IEEE standard to better suit deep learning workloads.

**Meta** - Technology company that embraced 8-bit training with their Llama 4 model, following the trend established by DeepSeek.

**Anthropic** - AI research company whose CEO revealed that training Claude 3.7 costs "a few tens of millions of dollars."

**Stanford** - University that produced a report estimating the training costs of major LLM models like Gemini Ultra and GPT-4.

**Nvidia** - GPU manufacturer worth a trillion dollars, creator of Tensor Cores and the primary hardware enabler of mixed-precision training. Described as the reason "why Nvidia is a trillion dollar company today."

**AMD, Intel, Qualcomm** - Hardware companies that collaborated with Nvidia to propose the microscaling (MX) data formats as industry standards.

### Models & Technologies

**Gemini Ultra** - Large language model from Google estimated to have cost just under $200 million in compute for training.

**GPT-4** - OpenAI's language model estimated to have cost about $100 million to train, though Sam Altman claimed this was an underestimation.

**Claude 3.7** - Anthropic's language model that cost "a few tens of millions of dollars" to train according to the CEO.

**DeepSeek V3** - The first high-quality production LLM to successfully implement FP8 training at scale in 2024, reducing memory requirements by 40% and increasing training speed by 1.8x.

**Llama 4** - Meta's language model that adopted 8-bit training following DeepSeek's success.

### Hardware Architectures

**Volta GPUs** - Nvidia GPU architecture from 2017 that introduced Tensor Cores just as deep learning was taking off.

**Hopper architecture** - Nvidia GPU generation that introduced native support for FP8 operations with accumulation in 32 bits; this is the architecture behind the H100 GPU.

**H100 GPU** - Nvidia's flagship GPU based on Hopper architecture with 132 streaming multiprocessors and 80GB of global memory, currently restricted from export to China but potentially acquired by DeepSeek through indirect channels.

**Blackwell** - Nvidia's latest GPU generation providing native support for FP4 operations, though currently very hard to procure. Expected to make 4-bit training more accessible.

### Research & Standards

**IEEE standard** - The de facto standard for floating-point formats that BFloat16 modified for deep learning purposes.

**Q-LoRA paper** - Research paper that introduced the Normal Float 4 (NF4) format, consisting of 16 handpicked values theoretically optimal for quantizing normally distributed real values.

**"Floating Point 4 All the Way" paper** - The main research paper discussed in the video, claiming to train entire models in FP4 while matching FP16 baseline precision.

**LAMBADA benchmark** - Evaluation benchmark mentioned as an exception among mostly classification-style tasks used to evaluate the FP4-trained models.

### Formats & Specifications

**BFloat16 (BF16)** - 16-bit floating-point format developed by Google Brain in 2018, modified from IEEE standard to better suit deep learning.

**MXFP4** - Microscaling floating-point 4 format that encapsulates 32 4-bit values (in E2M1 format) plus a single 8-bit scale value.

**NVFP4** - Nvidia's alternative to MXFP4 format with a scale using 4 bits for exponent and 3 for mantissa, found to produce slightly better model performance.

**E2M1 format** - Floating-point representation with 2 bits for exponent and 1 bit for mantissa, used for block values in MXFP4.

**Normal Float 4 (NF4)** - Format from Q-LoRA paper consisting of 16 handpicked values optimized for normally distributed weights, but doesn't map well to existing hardware.

**INT4** - 4-bit integer format used in earlier quantization research, but less optimal than FP4 for model weights due to uniform bin spacing.

### Other Technical Terms

**US-China export controls** - Ongoing trade restrictions that theoretically prevent Chinese AI labs from acquiring advanced Nvidia GPUs like the H100.

**Congressional report (April 2025)** - Document suggesting DeepSeek might have procured H100s through indirect channels despite export restrictions.

**Patreon** - Platform where the presenter shares reading lists and slide decks for free for viewers who want to dive deeper into the topics.

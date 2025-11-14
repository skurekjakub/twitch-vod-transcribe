Great question! The conversation context flows through the handoff in a specific way:

## How Context is Passed

### What Gets Transferred

When you click a handoff button (e.g., "🚀 Start Implementation"):

```
New Agent Chat Context =
  1. Target agent's instructions (from .agent.md body)
  2. Handoff prompt (from the button you clicked)
  3. Previous agent's LAST RESPONSE (the message right before the handoff button)
  4. User's conversation history in that thread
```

### Visual Example

```
User: @Orchestrator "Create a batch video processor"

@Orchestrator: [Responds with detailed plan]
               
               Here's the implementation plan:
               1. Create batch-processor.sh
               2. Add parallel processing with GNU parallel
               3. Implement progress tracking
               ...
               
               [🚀 Start Implementation] [📝 Document Only]
```

**When you click "🚀 Start Implementation":**

```
@Coder receives:
  ├─ [Coder's full instructions from coder.agent.md]
  ├─ [Handoff prompt]: "Implement the plan outlined above..."
  └─ [Orchestrator's response]: The full plan text above ⬆️
```

## Important Notes

### ✅ Context Included
- The **immediate previous message** (Orchestrator's plan)
- The **chat history** from that conversation
- Any **files referenced** in the conversation

### ❌ NOT Included by Default
- The entire conversation history from **other agents**
- Messages from **different chat sessions**
- File contents unless explicitly referenced

## Best Practices for Handoffs

### 1. **Reference What Was Discussed**
```yaml
prompt: "Implement the plan outlined above..."
```
"above" refers to the previous agent's response ✅

### 2. **Be Explicit About Context**
```yaml
prompt: "Using the architecture decisions from the analysis, 
implement the three components discussed: batch processor, 
error handler, and logger."
```

### 3. **Reference Specific Sections**
```yaml
prompt: "Implement the 'Implementation Steps' section from 
the plan above, starting with the lib/ components."
```

## Your Current Handoffs

### Orchestrator → Coder
```yaml
prompt: "Implement the plan outlined above, focusing on 
Linux-compatible solutions and bash scripting best practices."
```
✅ "the plan outlined above" = Orchestrator's full response

### Orchestrator → Docs  
```yaml
prompt: "Document the components and workflows described 
in the analysis above. For transcript analysis workflows, 
reference the prompt templates in .github/prompts/..."
```
✅ "analysis above" = Orchestrator's analysis response

### Coder → Docs
```yaml
prompt: "Document the code changes I just implemented, 
including usage examples and technical details."
```
✅ "I just implemented" = Coder's implementation details

## Pro Tip: Chain Context

If you need to preserve context across **multiple** handoffs:

```yaml
# Orchestrator → Coder
prompt: "Implement the plan above. Preserve the requirements 
list for documentation."

# Coder → Docs  
prompt: "Document the implementation. Reference the original 
requirements from the Orchestrator's plan at the start of 
this conversation."
```

The **entire conversation thread** stays available, so Docs can see what Orchestrator said, even though Coder was in between! 🔄
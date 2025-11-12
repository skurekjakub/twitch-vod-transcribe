# Custom VS Code Copilot Agents

This directory contains a chain of specialized AI agents designed to work together in a coordinated workflow using VS Code's custom agent system.

## Agent Chain Overview

The agents form a sequential workflow with handoffs between specialized roles:

```
Orchestrator → Coder → Docs → Reviewer → Verifier
                 ↑                 |
                 └─────────────────┘
```

## Agents

### 1. 🎯 Orchestrator
**Role**: Requirements Analysis & Planning  
**Agent Name**: `@Orchestrator`

Analyzes high-level requirements and creates detailed implementation plans.

**Responsibilities**:
- Break down vague requests into specific requirements
- Create step-by-step implementation plans
- Gather context from existing codebase
- Identify dependencies and risks

**Tools**: search, fetch, githubRepo, usages

**Handoffs**: 
- → Coder (Start Implementation) - for new code
- → Docs (Document Existing Code) - for documentation-only tasks

---

### 2. 💻 Coder
**Role**: Linux-Focused Implementation  
**Agent Name**: `@Coder`

Implements features using bash scripts and Python, optimized for Linux environments.

**Responsibilities**:
- Write robust bash scripts with proper error handling
- Follow Linux/Unix best practices
- Implement features from plans
- Use modular, reusable components

**Tools**: edit, search, usages

**Handoff**: → Docs (Generate Documentation)

---

### 3. 📝 Docs
**Role**: Technical Documentation  
**Agent Name**: `@Docs`

Creates comprehensive documentation for code and features.

**Responsibilities**:
- Write clear script headers and usage guides
- Create README files with examples
- Document APIs and interfaces
- Provide troubleshooting guides

**Tools**: search, usages, edit

**Handoff**: → Reviewer (Code Review)

---

### 4. 🔍 Reviewer
**Role**: Code Quality & Security  
**Agent Name**: `@Reviewer`

Reviews code for quality, security vulnerabilities, and best practices.

**Responsibilities**:
- Check code quality and standards
- Identify security vulnerabilities
- Verify error handling
- Review documentation accuracy

**Tools**: search, usages, edit

**Handoffs**: 
- → Verifier (User Verification) - if approved
- → Coder (Fix Issues) - if changes needed

---

### 5. ✅ Verifier
**Role**: End-User Quality Assurance  
**Agent Name**: `@Verifier`

Tests implementation from end-user perspective with real-world scenarios.

**Responsibilities**:
- Functional testing with realistic data
- Usability and UX evaluation
- Edge case testing
- Integration testing

**Tools**: search

**Handoffs**:
- → Orchestrator (Complete) - if passed
- → Coder (Fix Issues) - if problems found

## Usage

### Starting a New Feature

1. **Talk to @Orchestrator**
   ```
   @Orchestrator Create a new script that downloads and processes multiple videos in parallel
   ```

2. **Review the Plan**
   - Orchestrator will analyze requirements and create a detailed plan
   - Choose your path:
     - Click "🚀 Start Implementation" to hand off to Coder for new code
     - Click "📝 Document Existing Code" to hand off to Docs for documentation only

3. **Implementation Path** (if you chose 🚀 Start Implementation)
   - Coder implements the feature
   - Click "📝 Generate Documentation" when done
   - Continue to step 4

3. **Documentation Path** (if you chose 📝 Document Existing Code)
   - Docs creates comprehensive documentation
   - Click "🔍 Code Review" to proceed to step 5

4. **Documentation** (Implementation path only)
   - Docs creates comprehensive documentation
   - Click "🔍 Code Review" to proceed

5. **Review**
   - Reviewer checks code quality and security
   - Click "✅ User Verification" if approved, or "🔄 Back to Coder" if issues found

6. **Verification**
   - Verifier tests with real-world scenarios
   - Click "🎉 Complete" if passed, or "🐛 Issues Found" to go back

### Quick Reference

| Agent | Use When You Need To... |
|-------|-------------------------|
| @Orchestrator | Plan a feature, analyze requirements, break down complex tasks |
| @Coder | Implement code, write scripts, fix bugs |
| @Docs | Document code, create usage guides, write README files |
| @Reviewer | Review code quality, check security, validate best practices |
| @Verifier | Test functionality, verify user experience, check edge cases |

## Agent Characteristics

### Orchestrator
- **Focus**: Planning & architecture
- **Output**: Detailed implementation plans
- **Tools**: Read-only (search, fetch)
- **Prevents**: Premature coding without planning

### Coder
- **Focus**: Implementation
- **Output**: Working code
- **Tools**: Full editing capabilities
- **Expertise**: Bash, Python, Linux tools

### Docs
- **Focus**: Documentation
- **Output**: README, usage guides, inline docs
- **Tools**: Read + edit documentation
- **Style**: Clear, example-driven

### Reviewer
- **Focus**: Quality & security
- **Output**: Review reports with actionable feedback
- **Tools**: Read + edit for fixes
- **Checks**: Security, best practices, standards

### Verifier
- **Focus**: User experience & testing
- **Output**: Test reports with reproduction steps
- **Tools**: Read-only analysis
- **Tests**: Real-world scenarios, edge cases

## Benefits

✅ **Separation of Concerns**: Each agent has a specific role and expertise  
✅ **Quality Gates**: Code goes through planning → implementation → documentation → review → testing  
✅ **Consistent Process**: Same workflow for all features  
✅ **Better Documentation**: Dedicated agent ensures docs are always created  
✅ **Security**: Dedicated review step catches vulnerabilities  
✅ **User Focus**: Verification step ensures good UX  

## Workflow Examples

### Example 1: New Feature
```
User → @Orchestrator "Add support for Spotify podcast transcription"
       ↓ (creates plan)
@Orchestrator → @Coder (🚀 Start Implementation)
       ↓ (implements feature)
@Coder → @Docs (📝 Generate Documentation)
       ↓ (documents feature)
@Docs → @Reviewer (🔍 Code Review)
       ↓ (reviews & approves)
@Reviewer → @Verifier (✅ User Verification)
       ↓ (tests & passes)
@Verifier → @Orchestrator (🎉 Complete)
```

### Example 2: Bug Fix with Issues
```
User → @Coder "Fix error handling in batch-transcribe.sh"
       ↓ (fixes bug)
@Coder → @Docs (📝 Generate Documentation)
       ↓ (updates docs)
@Docs → @Reviewer (🔍 Code Review)
       ↓ (finds issues)
@Reviewer → @Coder (🔄 Back to Coder - Fix Issues)
       ↓ (fixes issues)
@Coder → @Docs (📝 Generate Documentation)
       ↓ (updates docs)
@Docs → @Reviewer (🔍 Code Review)
       ↓ (approves)
@Reviewer → @Verifier (✅ User Verification)
```

## Customization

Each agent is defined in a `.agent.md` file with:
- **Frontmatter**: Metadata (name, description, tools, handoffs)
- **Body**: Detailed instructions and guidelines

To customize an agent:
1. Open `.github/agents/{agent-name}.agent.md`
2. Edit the frontmatter or body
3. Save - changes take effect immediately

## Project Context

These agents are optimized for this **Twitch/YouTube transcription pipeline**:
- Environment: Linux (Ubuntu 22.04)
- Languages: Bash, Python
- Tools: ffmpeg, yt-dlp, twitch-dl, faster-whisper
- Focus: Robustness, error handling, GPU support

## Tips

💡 **Start with Orchestrator** for complex tasks - get a plan first  
💡 **Jump to Coder** for quick fixes or small changes  
💡 **Use Reviewer** before committing important changes  
💡 **Invoke Verifier** to test before releasing to users  
💡 **Read agent instructions** in `.agent.md` files to understand capabilities  

## See Also

- [VS Code Custom Agents Documentation](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [Project README](../../README.md)
- [Project Usage Guide](../../USAGE.md)

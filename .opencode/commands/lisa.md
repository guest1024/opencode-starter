---
description: Lisa - intelligent epic workflow (/lisa help for commands)
agent: general
---

**Arguments:** $ARGUMENTS

---

**If the user ran `/lisa` with no arguments or `/lisa help`, output EXACTLY this and STOP:**

**Lisa - Intelligent Epic Workflow**

**Available Commands:**

`/lisa list` - List all epics and their status  
`/lisa <name>` - Continue or create an epic (interactive)  
`/lisa <name> spec` - Create/view the spec only  
`/lisa <name> status` - Show detailed epic status  
`/lisa <name> yolo` - Auto-execute mode (no confirmations)  
`/lisa config view` - View current configuration  
`/lisa config init` - Initialize config with defaults  
`/lisa config reset` - Reset config to defaults  

**Examples:**
- `/lisa list` - See all your epics
- `/lisa auth-system` - Start or continue the auth-system epic
- `/lisa auth-system yolo` - Run auth-system in full auto mode

**Get started:** `/lisa <epic-name>`

**DO NOT call any tools. DO NOT load the skill. Just output the above and stop.**

---

**Otherwise (if arguments were provided):**

Load the lisa skill for detailed instructions and handle the command.

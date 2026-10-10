# QUEST SYSTEM

Not required for MVP, but architecture should allow it (services emit signals a quest system can listen to later).

Quest structure:
- id
- title
- description
- objective
- progress
- requirement
- reward
- completion state

Examples:
- recruit first Hunter
- complete first expedition
- defeat Forest Guardian
- upgrade Blacksmith

Quest system must not directly own combat logic.

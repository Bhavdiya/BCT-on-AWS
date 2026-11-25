# Replace every placeholder before running plan.
# None of these have defaults, so an unreplaced value fails loudly rather than
# deploying something wrong.

region             = "<AWS_REGION>"
project            = "<PROJECT_NAME>"
db_master_username = "<DB_MASTER_USERNAME>"

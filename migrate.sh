#!/bin/bash
RD='\033[0;31m' # Red
YW='\033[0;33m' # Yellow
NC='\033[0m' # No Color
GR='\033[0;32m' # Green

# ENV
DB_DATABASE="line_execution"
DB_HOST="localhost"
DB_USERNAME="postgres"

DOCKER_HOST_NAME="postgres"
MAINT_CONTROL_SCHEMA="maint"
LATAM_SCHEMA="latam"
NEW_DATABASE="line_execution.sql"
NEW_DATABASE_ZIP="${NEW_DATABASE}.gz"
ROUTE=$(pwd)

clear
echo $(pwd)
echo "What do you need? (Select an option)"
echo
echo "1.- [Reset Schemas]"
echo "2.- [Migrate Workpackage]"
echo "3.- [Update sequence]"
echo "4.- [Back Up Line Excecution]"
echo "5.- [Restore Maint Control]"
echo "0.- [Exit]"
echo
echo "Input your choice: "
read -n 2 OPTION
echo

if [[ $OPTION = "1" ]] ;then
    clear
    echo "Restting Schemas ...."
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < ./sql/resetSchemas.sql

    echo "${YW}Migrate Maint Control to database: ${YW}" $DB_DATABASE "${GR}schema: ${YW}" $MAINT_CONTROL_SCHEMA "${NC}"
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/sql/dumps/maint_control.sql
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/sql/publicToMaint.sql

    echo "${YW}Migrate Latam to database: ${YW}" $DB_DATABASE "${GR}schema: ${YW}" $LATAM_SCHEMA "${NC}"
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/sql/dumps/lancass.sql
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/sql/publicToLatam.sql

    # echo "${YW}Remove Duplicate CONSTRAINT for: ${YW}" $DB_DATABASE "${NC}"
    # docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/sql/pgConstraint.sql
    echo "${GR} Done! ${NC}"


elif [[ $OPTION = "2" ]] ;then
    clear
    echo "${YW}Migrate Work Package to database: ${YW}" $DB_DATABASE "${NC}"
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/sql/dumps/work_package.sql

    echo "${YW}Remove Old tables into database: ${YW}" $DB_DATABASE "${NC}"
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/sql/dropOldTables.sql
    echo "${GR} Done!! ${NC}"

elif [[ $OPTION = "3" ]] ;then
    clear
    . ~/.nvm/nvm.sh
    nvm use
    node sequence/main.js
    echo "${GR} Done!! ${NC}"

elif [[ $OPTION = "4" ]] ;then
    clear
    echo "${YW}Remove old backup .... ${NC}"
    rm -rf $ROUTE/backUps/$NEW_DATABASE
    echo "${YW}Creating Line Excecution BackUp ....${NC}"
    docker exec -i $DOCKER_HOST_NAME pg_dump -v -O -n public -x -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE | gzip -3 -c > $ROUTE/backUps/$NEW_DATABASE_ZIP
    echo "${GR} You can see the backup into ${ROUTE}/backUps/${NEW_DATABASE} ${NC}"
    echo "${GR} Done!! ${NC}"

elif [[ $OPTION = "5" ]] ;then
    clear
    DB_DATABASE="maint_control"
    DB_HOST="localhost"
    DB_USERNAME="postgres"
    docker exec -i $DOCKER_HOST_NAME psql -U $DB_USERNAME -w -h $DB_HOST $DB_DATABASE < $ROUTE/backUps/maint_control.sql
    echo "${GR} Done ${NC}"
else
    clear
    echo "bye..."
fi

# psql -h localhost -U postgres line_execution
# Force drop database
# UPDATE pg_database SET datallowconn = 'false' WHERE datname = 'line_execution';
# docker exec -i postgres psql -U postgres -w -h localhost line_execution < ITI_FLIGHT_LEGS.sql



# drop database line_execution;
# docker exec -i $DOCKER_HOST_NAME pg_restore --schema="${DOCKER_HOST_NAME}" --dbname=$DATABASE --username=$DB_USERNAME /usr/databases/maint_control.sql

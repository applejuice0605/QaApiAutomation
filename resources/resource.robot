*** Settings ***
Library     BuiltIn
Library     env/load_env.py


*** Variables ***
${WAIT_FOR_IDLE_TIMEOUT}    10
${TIMEOUT}                    60s


*** Keywords ***
Setup Env Variable
    [Documentation]    Setup Data Environtment
    ${env_vars}    Load Environment
    Set Test Variable    ${env_vars}





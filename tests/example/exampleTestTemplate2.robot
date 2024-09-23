*** Settings ***
Documentation     Example test cases using the data-driven testing approach.
Test Template     CalculateJerry
Library           CalculatorLibrary.py
Library     DebugLibrary

*** Variables ***
${NUMBER_1}       10
${NUMBER_2}       5
${RESULT_ADD}     ${NUMBER_1}+${NUMBER_2}
${RESULT_SUBTRACT}   ${NUMBER_1}-${NUMBER_2}
${RESULT_MULTIPLY}   ${NUMBER_1}*${NUMBER_2}
${RESULT_DIVIDE}     ${NUMBER_1}/${NUMBER_2}

# poetry run robot --listener allure_robotframework:log4  tests/example/exampleTestTemplate2.robot
*** Test Cases ***
Addition Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    add    ${RESULT_ADD}
    ${NUMBER_1}    ${NUMBER_2}    addId    ${RESULT_ADD}


Subtraction Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    subtract    ${RESULT_SUBTRACT}

Multiplication Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    multiply    ${RESULT_MULTIPLY}
    ${NUMBER_1}    ${NUMBER_2}    divide    ${RESULT_DIVIDE}


Division Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    divide    ${RESULT_DIVIDE}

*** Keywords ***
CalculateJerry
    [Arguments]    ${a}    ${b}    ${operation}    ${expected}
    #${result}    Run Keyword And Return    ${operation}    ${a}    ${b}  # Assuming the library has a keyword named ${operation}
    #debug
    ${result}    Return From Keyword    ${operation}    ${a}    ${b}  # Assuming the library has a keyword named ${operation}
    #debug
    Should Be Equal    ${result}    ${expected}
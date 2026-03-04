*** Settings ***
Documentation     Example test cases using the data-driven testing approach.
Test Template     CalculateJerry
Library           CalculatorLibrary.py

*** Variables ***
${NUMBER_1}       10
${NUMBER_2}       5
${RESULT}            ${EMPTY}

*** Test Cases ***
Addition Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    add    ${RESULT}=${NUMBER_1}+${NUMBER_2}

Subtraction Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    subtract    ${RESULT}=${NUMBER_1}-${NUMBER_2}

Multiplication Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    multiply    ${RESULT}=${NUMBER_1}*${NUMBER_2}

Division Test
    [Template]    CalculateJerry
    ${NUMBER_1}    ${NUMBER_2}    divide    ${RESULT}=${NUMBER_1}/${NUMBER_2}

*** Keywords ***
CalculateJerry
    [Arguments]    ${a}    ${b}    ${operation}    ${expected}
    ${result}    ${operation}    ${a}    ${b}
    Should Be Equal    ${result}    ${expected}


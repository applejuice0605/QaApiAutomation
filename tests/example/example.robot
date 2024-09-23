*** Settings ***
Library    SeleniumLibrary

*** Test Cases ***
Example Test Case
    [Documentation]    Example test case to demonstrate Robot Framework with SeleniumLibrary.
    Open Browser    http://baidu.com    Chrome
    Title Should Be    Baidu
    Close Browser

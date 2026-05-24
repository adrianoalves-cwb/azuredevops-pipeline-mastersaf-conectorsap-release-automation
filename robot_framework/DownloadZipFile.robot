*** Settings ***
Library    SeleniumLibrary
Library    SeleniumExtension.py
Library    OperatingSystem
Library    String

*** Variables ***
${URL}    #{TR_WEBSITE_LINK}#
${ZipFileXPath}    #{ZIP_FILE_XPATH}#

${USERNAME}   #{USERNAME}#
${PASSWORD}   #{PASSWORD}#

#${file_path}   #{TEMP_FOLDER}#\\\\Version.txt
${Browser}    firefox

*** Keywords ***

*** Test Cases ***
Validate the Page title

    Log To Console    Opening the Browser
    ${profile_dir}    Set Up Firefox Profile
    Open Browser       ${URL}    ${Browser}    ff_profile_dir=${profile_dir}
    
    Maximize Browser Window

    Log To Console    Login to Mastersaf
    #----LOGIN----
    Sleep   10s
    Input Text      id=:Rhdp8m:--input    ${USERNAME}
    Input Password  id=:R2pdp8m:--input    ${PASSWORD}
    Click Element   xpath=//button[text()='Entrar']

    #----DOWNLOAD ZIP FILE----
    Sleep   10s
    Log To Console    Downloading the Zip File
    Click Element    ${ZipFileXPath}

    Log To Console    Completed!

    Sleep    60 seconds

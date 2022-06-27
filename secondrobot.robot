*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc
...               Save the order html recipt as a PDF file
...               Save a screenshot of each ordered robot
...               Embed the screenshot of the robot to the PDF receipt
...               Create a ZIP archive of the PDF receipts
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Excel.Application
Library           RPA.Tables
Library           RPA.Desktop
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
#${URL}           https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_AMOUNT}=    3x
${GLOBAL_RETRY_INTERVAL}=    0.5s
${PDF_TEMPLATE_PATH}=    ${CURDIR}${/}devdata${/}pdfs
${PATH_SCREENSHOTS}    ${OUTPUT_DIR}${/}screenshots${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying module
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    ${URL}=    URL Input Form Dialog
    Open Available Browser    ${URL}

Get orders
    ${secret}=    Get Secret    CSVURL
    Log    ${secret}[URL]
    Download    ${secret}[URL]    overwrite=TRUE
    ${orders}=    Read table from CSV    orders.csv    header=TRUE
    [Return]    ${orders}

URL Input Form Dialog
    Add heading    Robot Order Website
    Add text input    search    label=Enter the Order Website URL
    ${response}=    Run dialog
    Log    ${response.search}    info
    [Return]    ${response.search}
#Get orders
    #    ${orders}=    Read table from CSV    orders.csv    header=TRUE
    #    [Return]    ${orders}

Close the annoying module
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Button    ${row}[Body]
    Input Text    class:form-control    ${row}[Body]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the Order
    Click Button    id:order
    ${Status} =    Run Keyword And Return Status    Submit the order
    Run Keyword if    ${Status} == 'False'    Submit the order

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_result_html}=    Get Element Attribute    id:receipt    outerHTML
    Log    ${order_result_html}    info
    Html To Pdf    ${order_result_html}    ${PDF_TEMPLATE_PATH}${/}${order_number}.pdf
    [Return]    ${PDF_TEMPLATE_PATH}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot}=    Screenshot    id:robot-preview-image    ${PATH_SCREENSHOTS}${order_number}.png
    Log    ${screenshot}    info
    [Return]    ${PATH_SCREENSHOTS}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${PDF_TEMPLATE_PATH}    ${zip_file_name}

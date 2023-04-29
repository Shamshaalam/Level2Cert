*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Desktop
Library             RPA.Archive
Library             DateTime
Library             RPA.RobotLogListener


*** Variables ***
${receipts}     ${OUTPUT_DIR}${/}receipts/
${images}       ${OUTPUT_DIR}${/}images/


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get orders file
    Open the robot order website
    Fill the form
    Close the browser and delete files
    Create a zip and empty receipts


*** Keywords ***
Get orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close popup
    Wait Until Page Contains Element    xpath://button[contains(text(), "OK")]
    Click Button    xpath://button[contains(text(), "OK")]

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Create an order
    Click Button    xpath://button[@id = "order"]
    Page Should Contain Element    xpath://div[@id = "receipt"]

Create each order
    [Arguments]    ${order}
    Close popup
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[@class = "form-control" and @type = "number"]    ${order}[Legs]
    Input Text    xpath://input[@id = "address"]    ${order}[Address]
    Click Button    xpath://button[@id = "preview"]
    Wait Until Keyword Succeeds    5x    500ms    Create an order

    Wait Until Element Is Visible    xpath://div[@id = "robot-preview-image"]
    ${screenshot}=    Screenshot    xpath://div[@id = "robot-preview-image"]    ${images}${order}[Order number].png
    Wait Until Element Is Visible    xpath://div[@id = "receipt"]
    ${order_receipt}=    Get Element Attribute    xpath://div[@id = "receipt"]    outerHTML
    Html To Pdf    ${order_receipt}    ${receipts}${order}[Order number].pdf

    Open Pdf    ${receipts}${order}[Order number].pdf
    @{my_list}=    Create List    ${images}${order}[Order number].png
    Add Files To Pdf    ${my_list}    ${receipts}${order}[Order number].pdf    ${True}
    Close Pdf    ${receipts}${order}[Order number].pdf

    Wait Until Element Is Visible    xpath://button[@id = "order-another"]
    Click Button    xpath://button[@id = "order-another"]

Fill the form
    ${orders}=    Get orders file
    FOR    ${order}    IN    @{orders}
        Create each order    ${order}
    END

Close the browser and delete files
    Close Browser
    Empty Directory    ${images}

Create a zip and empty receipts
    ${orders_date}=    Get Current Date    exclude_millis=True
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Orders_${orders_date}.zip
    Archive Folder With Zip    ${receipts}    ${zip_file_name}
    Empty Directory    ${receipts}

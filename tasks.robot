*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}  
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Excel.Files
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem

*** Variables ***
${orders}
${pdf}
${screenshot}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the order website
    Get orders
Minimal task
    Log    Done.

*** Keywords ***
  
Open the order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    #Wait Until Page Contains    css:div.modal-dialog
    Maximize Browser Window
    Click Button    OK
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true
    ${orders}=    Read table from CSV    orders.csv    header=true
     FOR    ${row}    IN    @{orders}
        #Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        #${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        #Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element     id-body-${row}[Body]
    Input Text    css:input.form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]
Preview the robot
    Click Button    preview
   # Element Should Not Exist    css:div.alert alert-danger
Submit the order
    Click Button    order
    [Timeout]    5s
    
Store the receipt as a PDF file 
    [Arguments]    ${Order number}
    ${element_exists}=    Is Element Visible    id:receipt
    IF   ${element_exists} 
        Wait Until Element Is Visible    id:receipt
        ${receipt-html}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${receipt-html}    ${OUTPUT DIR}${/}receipts\\receipt-${Order number}.pdf
        Take a screenshot of the robot    ${Order number}
    ELSE
        Sleep    5s
        Preview the robot
        Submit the order
        Store the receipt as a PDF file    ${Order number}
    END
   
    
Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}screenshots\\${Order number}.png
    Embed the robot screenshot to the receipt PDF file    ${Order number}
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${Order number} 
    #Open Pdf    ${OUTPUT DIR}${/}receipt-${Order number}.pdf
    ${robotSCreen}=    Create List     ${OUTPUT DIR}${/}receipts\\receipt-${Order number}.pdf
    ...    ${OUTPUT_DIR}${/}screenshots\\${Order number}.png 
    
    Add Files To Pdf    ${robotSCreen}    ${OUTPUT DIR}${/}report\\receipt-${Order number}.pdf 
         
    #Close Pdf    ${OUTPUT DIR}${/}report\\receipt-${Order number}.pdf    
Go to order another robot 
    Click Button    order-another
    Click Button    OK

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT DIR}${/}report
    ...    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${OUTPUT_DIR}${/}screenshots    True    
    Remove Directory    ${OUTPUT DIR}${/}report    True
    Remove Directory    ${OUTPUT DIR}${/}receipts    True
    Create Directory    ${OUTPUT_DIR}${/}screenshots
    Create Directory    ${OUTPUT DIR}${/}report
    Create Directory    ${OUTPUT DIR}${/}receipts
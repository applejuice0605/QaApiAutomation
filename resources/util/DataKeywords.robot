
[Documentation]
...    数据处理关键字库
...    提供了一些常用的数据处理操作，如占位符替换、数据提取等。
...    1. 占位符替换 (Cope With Placeholders)
...    2. 数据提取 (Extract Data From DbResult)
...    3. 链接组装和验证 (Assemble And Validate Link)


*** Settings ***
# 导入所需的内建库
Library    Collections    # 用于处理字典和列表 (Get From Dictionary, Set To Dictionary, etc.)
Library    String         # 用于字符串操作 (Replace String)


*** Keywords ***
Cope With Placeholders
    [Documentation]    递归地将占位符替换为 Context 中的值。
    [Arguments]    ${data}    ${context}
    
    # 获取数据类型
    ${data_type}    Evaluate    type(${data}).__name__
    Log    ${data_type}
    # 如果是字符串，直接替换
    IF    ${data_type} == 'str'
        ${temp_data}=    Set Variable    ${data}
        FOR    ${key}    IN    &{context}
            ${placeholder}=    Set Variable    ${{${key}}}
            ${temp_data}=    Replace String    ${temp_data}    ${placeholder}    ${context}[${key}]
        END
        RETURN    ${temp_data}

    # 如果是字典，递归处理字典的值
    ELSE IF    ${data_type} == 'dict'
        &{new_dict}=    Create Dictionary
        FOR    ${key}    IN    &{data}
            ${new_value}=    Cope With Placeholders    ${data}[${key}]    &{context}
            Set To Dictionary    ${new_dict}    ${key}    ${new_value}
        END
        RETURN    &{new_dict}

    # 如果是列表，递归处理列表的元素
    ELSE IF    ${data_type} == 'list'
        @{new_list}=    Create List
        FOR    ${item}    IN    @{data}
            ${new_item}=    Cope With Placeholders    ${item}    &{context}
            Append To List    ${new_list}    ${new_item}
        END
        RETURN    @{new_list}
    
    # 其他类型直接返回
    ELSE
        RETURN    ${data}
    END

#根据Step Item中的extract字段提取数据
Extract Data From DbResult
    [Documentation] 
    [Arguments]    ${extract}    ${db_checkResult}    &{CONTEXT}
    Log    ${extract}
    ${len}=    Evaluate    len(${extract})
    Log    ${len}
    # 如果${extract}为空，跳过数据提取
    IF    ${len} > 0
        FOR    ${extractItem}    IN    @{extract}
            Log    ${extractItem}
            ${extract_keys}=    Get Dictionary Keys    ${extractItem}
            Log    ${extract_keys}
            FOR    ${extract_key}    IN    @{extract_keys}
                Log    ${extract_key}
                ${extract_method}=    Get From Dictionary    ${extractItem}    ${extract_key}
                Log    ${extract_key}
                Log    ${extract_method}
                ${extracted_value}=    Run Keyword    ${extract_method}    ${db_checkResult}
                Log    ${extracted_value}
                Set To Dictionary    ${CONTEXT}    ${extract_key}    ${extracted_value}
                Log    Context Updated: ${extract_key}=${extracted_value}
            END
            
        END
    END
    RETURN    &{CONTEXT}

#根据路径提取数据
Extract Data From DbResult With DBPath
    [Documentation]
    # 根据 Step Item 中的 'extract' 字段，从 DB 结果中提取数据并更新 &{CONTEXT}。
    # 提取的路径目前假设是简单的字典键。
    [Arguments]    ${stepItem}    ${db_checkResult}    &{CONTEXT}
      
    ${extract_map}=    Get From Dictionary    ${stepItem}    extract    default=${EMPTY}
    
    Run Keyword If    '${extract_map}' == '${EMPTY}'    Return From Keyword
    
    FOR    ${context_key}    ${db_path}    IN    &{extract_map}
        Log    Attempting to extract: ${db_path} as ${context_key}
        
        # 从 db_checkResult 中提取值
        ${extracted_value}=    Get From Dictionary    ${db_checkResult}    ${db_path}    default=${None}
        
        # 提取失败警告
        Run Keyword If    '${extracted_value}' == '${None}'
        ...    Log To Console    WARNING: Could not find key ${db_path} in DB result for extraction.
        
        # 提取成功，更新全局上下文
        Run Keyword If    '${extracted_value}' != '${None}'
        ...    Set To Dictionary    ${CONTEXT}    ${context_key}    ${extracted_value}
        ...    Log    Context Updated: ${context_key}=${extracted_value}
    END

Assemble And Validate Link
    [Documentation]    
    # 处理 alertSteps 中的链接模板，使用 &{CONTEXT} 组装链接，并进行简单验证。
    [Arguments]    ${stepItem}    &{CONTEXT}
    
    ${alertSteps}=    Get From Dictionary    ${stepItem}    alertSteps    default=${EMPTY}
    Run Keyword If    '${alertSteps}' == '${EMPTY}'    Return From Keyword
    
    FOR    ${alertItem}    IN    @{alertSteps}
        ${template}=    Get From Dictionary    ${alertItem}    link_template    default=${EMPTY}
        ${expected_link}=    Get From Dictionary    ${alertItem}    expected_link    default=${EMPTY}

        Run Keyword If    '${template}' == '${EMPTY}'    Continue For Loop
        
        Log    Link Template Found: ${template}
        
        # 使用 Cope With Placeholders 替换模板中的占位符来组装链接
        ${assembled_link}=    Cope With Placeholders    ${template}    &{CONTEXT}
        Log    Assembled Link: ${assembled_link}
        
        # 链接验证逻辑 (这里假设 expected_link 是 JSON 中的预期值)
        # 实际项目中，您可能需要从数据库中获取 Fina 实际返回的链接进行比对
        IF    '${expected_link}' != '${EMPTY}'
            Should Be Equal As Strings    ${assembled_link}    ${expected_link}
        ELSE
            Log    Note: No explicit 'expected_link' found for validation. Assembled link: ${assembled_link}
        END
    END
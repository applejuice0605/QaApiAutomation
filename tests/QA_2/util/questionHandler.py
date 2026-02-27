#定义questionHandler类，用于存储不同问题场景的问题处理方法
from tests.QA_2.fileProcess import FileProcess


def process_excel(input_file, output_file):

    # 读取文件
    df = FileProcess.real_excel(input_file)

    # 处理每个问题
    index_start = 0

    round = 15
    for index, row in df.iloc[index_start:].iterrows():
        # 每16轮重新获取token
        if round % 16 == 15:
            token = login()

        round += 1

        # 获取当前行问题
        question = str(row['问题']).strip()
        # 获取当前行标准答案，暂时没有多轮对话给标答的情况不拆分
        standard_answer = str(row['标准答案'])

        if not question or question.lower() == 'nan' or question == '' or question == '-':
            continue

        print(f"\n处理问题 {index + 1}/{len(df)}: {question}")
        knowledge_highestScore = None

        # 2. 调用chatflow处理问题
        # 2.1 分解这个问题的每个步骤
        steps = [q for q in re.split(r'\d+\.', question) if q]
        print("全部步骤：", steps)

        output_answer = ''
        output_question_rephase= ''
        output_level1_question_classifier = ''
        output_knowledge_retrieval = ''
        output_question_classifier = ''
        output_evalsition = ''
        output_knowledge_highestScore = ''

        # 2.2 逐个步骤调用chatFlow / workflow
        for step_index in range(0, len(steps)):
            answer, question_rephase, Level1_question_classifier, question_classifier, knowledge_retrieval = None, None, None, None, None
            print(f"处理步骤{step_index+1}/{steps.__len__()}: {steps[step_index]}")


            # 调用chatFlow
            result = chat_chatlow(steps[step_index], token)

            # if result is not No
            if result is not None:
                answer, question_rephase, Level1_question_classifier, question_classifier, knowledge_retrieval = result
            else:
                # 处理 None 的情况，例如抛出异常或返回默认值
                print("chat_chatlow 返回了 None")
                continue

            # 截取最高分的知识
            print("check knowledge_retrieval before json.loads: ", knowledge_retrieval)
            # 如果knowledge_retrieval 不等于Null, 将knowledge_retrieval转换成列表
            if knowledge_retrieval is not None and knowledge_retrieval != '':
                knowledge_retrieval_temp = json.loads(knowledge_retrieval)
                print("knowledge_retrieval_temp: ", knowledge_retrieval_temp)
                if knowledge_retrieval_temp and len(knowledge_retrieval_temp) > 0:
                    #  获取列表第一条，最高分的知识
                    knowledge_highestScore = knowledge_retrieval_temp[0]
                    # 转换成字符串
                    knowledge_highestScore = json.dumps(knowledge_highestScore)
                    print("知识库最高分: ", knowledge_highestScore)
                else:
                    knowledge_highestScore = "None"
            else:
                knowledge_highestScore = "None"

            # 评估答案
            evalsition = evalsite_answer(steps[step_index], answer, token, standard_answer)
            if not evalsition:
                print(f"评估答案失败，跳过问题: {question}")
                continue
            print(f"评测结果: {evalsition}")
            print("=" * 200)

            # 保存答案
            # 答案
            output_answer += f"{step_index+1}. " + answer + '\n'
            # 问题拆分重写结果和意图识别优先级结果
            output_question_rephase += f"{step_index+1}. " + question_rephase + '\n'
            # chatflow意图分类结果
            output_level1_question_classifier += f"{step_index+1}. " + Level1_question_classifier + '\n'
            # 最终问题分类结果
            output_question_classifier += f"{step_index+1}. " + question_classifier + '\n'
            # 知识库检索结果
            output_knowledge_retrieval += f"{step_index+1}. " + knowledge_retrieval + '\n'
            # 知识库最高分
            output_knowledge_highestScore += f"{step_index+1}. " + knowledge_highestScore + '\n'
            # 评测结果
            output_evalsition += f"{step_index+1}. " + evalsition + '\n'


        # 更新DataFrame
        df.at[index, '答案'] = output_answer
        df.at[index, '意图识别与拆分重写结果'] = output_question_rephase
        df.at[index, 'Level1_question_classifier'] = output_level1_question_classifier
        df.at[index, 'question_classifier'] = output_question_classifier
        df.at[index, 'knowledge_retrieval'] = output_knowledge_retrieval
        df.at[index, '最高分知识'] = output_knowledge_highestScore
        df.at[index, '评估结果'] = output_evalsition
        # print(f"评测结果: {evalsition}")
        print("="*200)

        # 每处理3条保存一次进度
        FileProcess.save_result_temp(index=index, df=df, output_file=output_file)

        # 最终保存结果
    FileProcess.write_to_excel(df, output_file)

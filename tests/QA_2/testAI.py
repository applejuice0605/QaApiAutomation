import re
import pandas as pd
from openai import OpenAI


class QuestionBot:
    def __init__(self, api_key: str, model: str = "gpt-4.1-mini"):
        self.client = OpenAI(api_key=api_key)
        self.model = model
        self.messages = [{"role": "system", "content": "你是一个刚接触保险的小白用户，你的任务是提出保险相关的问题。"}]

    def generate_question(self, hint: str = None) -> str:
        prompt = "请提出一个新的保险问题。"
        if hint:
            prompt = f"请提出一个和 {hint} 相关的保险问题。"
        self.messages.append({"role": "user", "content": prompt})
        response = self.client.chat.completions.create(model=self.model, messages=self.messages)
        question = response.choices[0].message.content.strip()
        self.messages.append({"role": "assistant", "content": question})
        return question


def req_chat_flow(question: str) -> str:
    """模拟 AI2（顾问）回答"""
    return f"[AI2 回答] 针对问题《{question}》，保险公司会根据保单条款判断是否赔付。"


class Evaluator:
    def __init__(self, api_key: str, model: str = "gpt-4.1-mini"):
        self.client = OpenAI(api_key=api_key)
        self.model = model
        self.system_prompt = (
            "你是一个保险对话的评估员。请基于问题和回答，评估以下方面："
            " 1. 回答是否和问题相关;"
            " 2. 回答是否完整;"
            " 3. 回答是否专业且易懂;"
            "请给出简短评估，并附 1-5 分的评分。"
        )

    def evaluate(self, question: str, answer: str) -> str:
        messages = [
            {"role": "system", "content": self.system_prompt},
            {"role": "user", "content": f"问题：{question}\n回答：{answer}"}
        ]
        response = self.client.chat.completions.create(model=self.model, messages=messages)
        return response.choices[0].message.content.strip()


def extract_score(evaluation: str) -> int:
    match = re.search(r"([1-5])\s*分", evaluation)
    return int(match.group(1)) if match else None


def run_test_to_excel(api_key: str, rounds: int = 5, output_file: str = "insurance_test.xlsx"):
    bot = QuestionBot(api_key)
    evaluator = Evaluator(api_key)

    results = []
    scores = []

    for i in range(rounds):
        question = bot.generate_question()
        answer = req_chat_flow(question)
        evaluation = evaluator.evaluate(question, answer)
        score = extract_score(evaluation)
        if score:
            scores.append(score)
        results.append({
            "round": i + 1,
            "question": question,
            "answer": answer,
            "evaluation": evaluation,
            "score": score
        })

    # 汇总统计
    summary = {
        "total_rounds": len(scores),
        "average_score": sum(scores) / len(scores) if scores else None,
        "max_score": max(scores) if scores else None,
        "min_score": min(scores) if scores else None
    }

    # 保存 Excel
    df = pd.DataFrame(results)
    with pd.ExcelWriter(output_file, mode="w") as writer:
        df.to_excel(writer, sheet_name="Results", index=False)
        pd.DataFrame([summary]).to_excel(writer, sheet_name="Summary", index=False)

    print(f"✅ 测试完成，结果已保存到 {output_file}")


# 运行示例
if __name__ == "__main__":
    API_KEY = "sk-xxxxxx"
    run_test_to_excel(API_KEY, rounds=5, output_file="insurance_test.xlsx")

import os
from dotenv import load_dotenv
from robot.api.deco import keyword
import string
import json

@keyword
def load_environment():
    env=load_dotenv('.env',override=True)
    env = os.getenv("MAIN_ENV", "uat")  # Default to UAT if ENV is not set
    print(env)

    if env == 'uat':
        load_dotenv('resources/env/uat.env')
    elif env == 'pre':
        load_dotenv('resources/env/pre.env')
    else:
        raise ValueError(f"Unknown environment: {env}")

    # 安全地解析FINA_USERINFO
    fina_userinfo_value = os.getenv("FINA_USERINFO", "{}")
    try:
        # 尝试直接解析
        fina_userinfo = json.loads(fina_userinfo_value)
    except json.JSONDecodeError:
        # 如果直接解析失败，尝试清理格式后再解析
        # 移除可能的换行符和多余空格
        cleaned_value = ''.join(line.strip() for line in fina_userinfo_value.splitlines())
        # 确保JSON字符串被引号包围
        if cleaned_value.startswith('{') and cleaned_value.endswith('}'):
            try:
                fina_userinfo = json.loads(cleaned_value)
            except json.JSONDecodeError:
                # 如果仍然失败，返回空字典
                print("Warning: Failed to parse FINA_USERINFO, using empty dict")
                fina_userinfo = {}
        else:
            fina_userinfo = {}

    return {
        "ENV": env,
        "FUSE_ACCOUNT": os.getenv("FUSE_ACCOUNT"),
        "FUSE_PASSWORD": os.getenv("FUSE_PASSWORD"),
        "TENANT_ID": os.getenv("TENANT_ID"),
        "KTP_NO": os.getenv("KTP_NO"),
        "EMAIL": os.getenv("EMAIL"),
        "BOSS_ACCOUNT": os.getenv("BOSS_ACCOUNT"),
        "BOSS_PASSWORD": os.getenv("BOSS_PASSWORD"),
        "UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE": os.getenv("UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE"),
        "UNDERWRITING_OFFLINE_EXISTSASSIGNEE": os.getenv("UNDERWRITING_OFFLINE_EXISTSASSIGNEE"),
        "DATA_BASEURL": 'resources/data/' + env + '/',
        "FINA_USERINFO": fina_userinfo

    }


@keyword
def change_env(key, value):
    env = load_dotenv('.env', override=True)
    print(env)
    env = os.getenv("MAIN_ENV")
    print(env)
    # env = os.getenv("ENV", "UAT")  # Default to UAT if ENV is not set
    if env == 'uat':
        load_dotenv('resources/env/uat/.env')
    elif env == 'pre':
        load_dotenv('resources/env/pre/.env')
    else:
        raise ValueError(f"Unknown environment: {env}")
    key.upper()
    print(key)
    os.environ[key] = value

    # dotenv_file = dotenv.find_dotenv(usecwd=True)
    # dotenv.load_dotenv(dotenv_file)
    #
    # print(os.environ["key"])  # outputs "value"
    # os.environ["key"] = "newvalue"
    # print(os.environ['key'])  # outputs 'newvalue'
    #
    # Write changes to .env file.
    # dotenv.set_key(dotenv_file, key, os.environ[key])

# 增加对load_environment方法的单元测试
if __name__ == "__main__":
    env = load_environment()
    print(env)
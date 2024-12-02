import os
from dotenv import load_dotenv
from robot.api.deco import keyword
import string

@keyword
def load_environment():
    env=load_dotenv('.env',override=True)
    env=os.getenv("MAIN_ENV")
    print(env)
    # env = os.getenv("ENV", "UAT")  # Default to UAT if ENV is not set


    if env == 'uat':
        load_dotenv('resources/env/uat.env')
    elif env == 'prod':
        load_dotenv('resources/env/prod.env')
    else:
        raise ValueError(f"Unknown environment: {env}")

    return {
        "FUSE_ACCOUNT": os.getenv("FUSE_ACCOUNT"),
        "FUSE_PASSWORD": os.getenv("FUSE_PASSWORD"),
        "TENANT_ID": os.getenv("TENANT_ID"),
        "KTP_NO": os.getenv("KTP_NO"),
        "EMAIL": os.getenv("EMAIL"),
        "BOSS_ACCOUNT": os.getenv("BOSS_ACCOUNT"),
        "BOSS_PASSWORD": os.getenv("BOSS_PASSWORD"),
        "UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE": os.getenv("UNDERWRITING_ORDER_REVIEW_EXISTSASSIGNEE"),
        "UNDERWRITING_OFFLINE_EXISTSASSIGNEE": os.getenv("UNDERWRITING_OFFLINE_EXISTSASSIGNEE")
    }


@keyword
def change_env(key, value):
    env = load_dotenv('.env', override=True)
    env = os.getenv("MAIN_ENV")
    print(env)
    # env = os.getenv("ENV", "UAT")  # Default to UAT if ENV is not set
    if env == 'uat':
        load_dotenv('resources/env/uat/.env')
    elif env == 'prod':
        load_dotenv('resources/env/prod/.env')
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
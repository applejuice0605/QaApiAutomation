import js2py

func_js = """
function getreCaptchaToken(isThird  = false) {
  console.log('getreCaptchaToken', getreCaptchaToken)
  grecaptcha.ready(function() {
    grecaptcha.execute(reCaptchaSiteKey, {action: 'submit'}).then(function(token) {
        return token;
    }, (error) => {
      console.log('grecaptcha.execute', error)
      return ''
    });
  });
}
"""

func_add = """
function add(a, b) {
  return a + b;
}
"""

func_getRecaptchaToken = """
function getreCaptchaToken() {
  console.log('getreCaptchaToken', getreCaptchaToken)
  grecaptcha.ready(function() {
    grecaptcha.execute(reCaptchaSiteKey, {action: 'submit'}).then(function(token) {
        return token;
    }, function(error) {
      console.log('grecaptcha.execute', error)
      return '';
    });
  });
}

"""

class TestSign:
    def __init__(self):
        pass

    def get_token(self):
        print('get_token')
        #example
        # context = js2py.EvalJs()
        # context.execute(func_add)
        # result = context.add(1, 2)
        print("1")
        context = js2py.EvalJs('getToken.js')
        print("2")
        context.execute(func_getRecaptchaToken)
        print("3")
        result = context.getreCaptchaToken()


        # js代码翻译
        # js2py.translate_file('./resources/js/init-firebase.js', './resources/js/init-firebase.py')

        # getreCaptchaToken = js2py.eval_js(func_js)
        # print(getreCaptchaToken())

        # # 调用整段js代码
        # context.execute(func_js)
        # # 利用上下文调用js中的方法，并指定输入参数
        # result = context.getreCaptchaToken()


        print("here")
        # print(result)
        # return f'{self.app_id}:{self.app_secret}'


if __name__ == '__main__':
    print(js2py.eval_js('console.log("hello world")'))
    TestSign().get_token()

// TODO: Replace the following with your app's Firebase project configuration
// var firebaseConfig = {
//   apiKey: "AIzaSyC91pqdrCOj0sR0OA74UbIUq4A3KR8oWBo",
//   authDomain: "fusepro-register.firebaseapp.com",
//   projectId: "fusepro-register",
//   storageBucket: "fusepro-register.appspot.com",
//   messagingSenderId: "240071484712",
//   appId: "1:240071484712:web:390d4e1868679456645c1d",
//   measurementId: "G-TQN79TM24K"
// }
// var FIREBASE_API_KEY = 'AIzaSyATBdEvARhPsf43O-QmCgVBpgRNWHxES3c'

// firebase : firebase
// domId:  需要绑定 recaptcha 人机识别的按钮 dom id
// recaptchaCallback:  发送验证码方法, recaptchaCallback 只会调用一次. dom上绑定了 recaptcha 的回调可以拿到 recaptcha token, 会导致第一次点击原来的点击方法拿不到recaptcha token, 因此这里需要调用一下.
// recaptchaCallback: 传入的方法里面建议啊加上这个判断 if(!firebaseApp.recaptchaToken) return; 
// firebaseConfig: firebase 配置
// authConfig: firebase.auth 相关配置 e.g. languageCode
function FirebaseApp (firebase, domId, recaptchaCallback, firebaseConfig = {}, authConfig = {}) {
  // 回调函数执行次数
  this.numExecuCallback = 0
  this.config = firebaseConfig
  firebase.initializeApp(firebaseConfig)
  firebase.auth.languageCode = authConfig.languageCode || 'en'
  this.recaptchaVerifier = new firebase.auth.RecaptchaVerifier(domId, {
    type: 'image', // 'audio'
    size: 'invisible', // 'invisible' or 'compact'
    badge: 'bottomright', //' bottomright' or 'inline' applies to invisible.
    callback: (recaptchaToken) => {
      // reCAPTCHA solved, allow signInWithPhoneNumber.
      this.recaptchaToken = recaptchaToken
      // console.log('recaptchaToken', recaptchaToken)
      if(typeof recaptchaCallback == 'function' && this.numExecuCallback == 0) {
        // console.log('recaptchaCallback 执行')
        recaptchaCallback()
        this.numExecuCallback += 1
      }
    }
  })
  // [START auth_phone_recaptcha_render]
  this.recaptchaVerifier.render().then((widgetId) => {
    this.recaptchaWidgetId = widgetId;
  });
  // [END auth_phone_recaptcha_render]
}

function loadreCaptchaScript(sitekey){
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src = `https://www.google.com/recaptcha/api.js?render=${sitekey}`;
  document.body.appendChild(script);
}

// var firebaseApp = new FirebaseApp(firebase, 'otp_btn', sendCode, firebaseConfig, {languageCode: 'en'})
// firebaseApp.FIREBASE_API_KEY = FIREBASE_API_KEY

// console.log('new firebaseApp ++++ ', firebaseApp)


var reCaptchaSiteKey = '6LeLzC4iAAAAAM09oGfzJY6Y0BG6bnmPOv5Wkq_n'
if(window.location.host === 'fuseinsurtech.com') { // 正式环境 
  reCaptchaSiteKey = '6Ldyzy4iAAAAAGDCQXOKY3vOSkia7wOlKbI3JKS7'
}
loadreCaptchaScript(reCaptchaSiteKey)

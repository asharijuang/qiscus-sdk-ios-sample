# Qiscus SDK iOS Sample

### Install Qiscus SDK

You need to use `pod` to install Qiscus SDK. 

Podfile file : 

```
target 'SampleSDK' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SampleSDK
  pod "Qiscus"

end
```


### Initiate Qiscus SDK in your project 

To initiate Qiscus SDK, you need to import Qiscus and then add this in your code (`AppDelegate`, `didFinishLaunchingWithOptions`)

```
Qiscus.setup(withAppId: YOUR_APP_ID, 
        userEmail: CURRENT_USER_EMAIL, 
        userKey: CURRENT_USER_PASSWORD, 
        username: CURRENT_USER_USERNAME, 
        avatarURL: CURRENT_USER_AVATAR_URL, 
        delegate: self, 
        secureURl: true
  )
```

For example : 
```
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        
        Qiscus.setup(withAppId: "DRAGONFLY",
                     userEmail: "e3@qiscus.com",
                     userKey: "password",
                     username: "Evan 3",
                     avatarURL: "https://qiscuss3.s3.amazonaws.com/uploads/36976206a8b1fd2778938dbcd72b6624/qiscus-dp.png",
                     delegate: self, secureURl: false)
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        
        return true
    }
```


### Start Chat with Target

Start chat with target is very easy, all you need is just call `Qiscus.chat(withUsers: ["TARGET_EMAIL"], target: self)` in your code

For example in your ViewController : 
```
import UIKit
import Qiscus

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(frame: CGRectMake(100,100,100,40))
        button.setTitle("Chat", forState: .Normal)
        button.backgroundColor = UIColor.redColor()
        self.view.addSubview(button)
        
        button.addTarget(self, action: #selector(ViewController.goToChat), forControlEvents: .TouchUpInside)
    }
    
    func goToChat(){
        print("go to chat")
        Qiscus.chat(withUsers: ["e2@qiscus.com"], target: self)
        
    }
}

```


### Custom Style of Chat Interface 

you can explore customisation of chat interface by calling method style

For Example : 

```
  Qiscus.style.color.leftBaloonColor = UIColor.blueColor()
  Qiscus.style.color.rightBaloonColor = UIColor.greenColor()
```


### Screen Shots

![alt tag](https://qiscuss3.s3.amazonaws.com/example@mail.com/xxx/02d03cb991ae1edf28c0ae6e738ce3aa/Screen+Shot+2016-09-15+at+6.05.41+AM.png)

![alt tag](https://qiscuss3.s3.amazonaws.com/example@mail.com/xxx/dcacfdf4af52939c3dc903ff462203ca/Screen+Shot+2016-09-15+at+6.06.39+AM.png)

![alt tag](https://qiscuss3.s3.amazonaws.com/example@mail.com/xxx/58e6dad7cf346d5eae1c00cb4f5f6f7e/Screen+Shot+2016-09-15+at+6.07.16+AM.png)



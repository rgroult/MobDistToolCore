![MDT icon](Doc/MDT_banner.png)  
#  Core Server
# 
[![Build, Test And Deploy](https://github.com/rgroult/MobDistToolCore/workflows/Test%20And%20Deploy/badge.svg)](https://github.com/rgroult/MobDistToolCore/actions)
[![codecov](https://codecov.io/gh/rgroult/MobDistToolCore/branch/master/graph/badge.svg)](https://codecov.io/gh/rgroult/MobDistToolCore) 

***

###Glossary

*Artifact*: A specific version of an application (etc: My great App V1.2.3) in an installable package (ex: IPA, APK)

*OTA*: Over the air.
***

# MDT

MDT is a mobile application OTA platform which allows to distribute and install multiple application's versions to registred users.

* **RESTful server**
* Artifacts can be **grouped for a specific version** to have multiples artifacts per version (ex: production, integration, dev,etc..)
* **Artifacts have a branch parameters to reflect your git branch workflow** (or other structure if you want) to be capable of produce same version between them if necessary (ex: version X.Y.Z on dev branch for tests before commit to master).
* **All registered applications are public for all registered users. No need to manage application acess by users**. 
* Users registration can be filtered by **white emails domains with activation email**.
* **Application has a specific version latest version** witch allows to provided latest builds to continuous tester after each build.
* **Install OTA for artifacts**.



# Mobile Distribution Tool Core

Rewrite of the Mobile Distribution Tool Core in  [swift/vapor](https://vapor.codes)

The UI (adaptated to new Core Apis) will be to another project.

## Supported Mobile platforms

MDT manage only **IOS And Android** OTA install for now (aka .ipa and .apk artifacts).

## Swagger

A swagger definition can be found [here](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/rgroult/MobDistToolCore/develop/Doc/swagger.json)

# Architecture

MDT Core is written in [swift/vapor](https://vapor.codes) with mongoDB database for Users,Application an artifacts metadata. Artifact files(.ipa, .apk) are stored on an external directory storage.

MDT web is written in progess...

## Getting Started

### Docker images
The easiest way to get ant test MDT is to use **[docker pre-built images][docker]**.

A sample platform using docker compose in provided in **docker_sample.yaml**.

Instructions to configure it is on configuration section.

[docker]:https://hub.docker.com/r/rgroult2/mobdisttool-core/

```
cat docker_sample.yaml 

version: '2'
services:
    mdtcore:
        image: "rgroult2/mobdisttool-core:latest"
        ports:
            - "8080:8080"
        environment:
            - MDT_mongoServerUrl=mongodb://mongo/mobdisttool
            - MDT_serverExternalUrl=http://localhost:8080
            - MDT_storageMode=FilesLocalStorage
            - MDT_storageConfiguration={"RootDirectory":"/tmp/mdt"}
        links:
            - mongo
    mongo:
        image: 'mongo:3.6'
```

Usage: 

```

docker-compose -f docker_sample.yaml up
```

### From sources

You can install manually MDT from the `master` branch and run:

```

swift run

>> Loading Config
>> Loading configuration from ...
>> ...
>> Server starting on http://0.0.0.0:8080

```

You can access server swagger UI on http://localhost:8080/swagger/index.html#/

**Note**: You need a reachable mongoDB server to start server.

# Configuration

Configuration can be done with a 'config.json' file in 'Sources/App/Config/<environment>' directory.
Each config key can be overridden by environnement value with same key prefixed by "MDT_".

Sample:

```

cat Sources/App/Config/envs/development/config.json 

{
    "serverListeningPort":8080,
    "basePathPrefix":"/api",
    "serverExternalUrl":"http://localhost:8080",
    "mongoServerUrl":"mongodb://localhost:27017/mobdisttool",
    "jwtSecretToken":"azze",
    "loginResponseDelay":0,
    "storageMode":"TestingStorage",
    "automaticRegistration":true,
    "minimumPasswordStrength":0,
    "initialAdminEmail":"admin@localhost.com",
    "initialAdminPassword":"password",
    "smtpConfiguration" : {"smtpServer":"gmail","smtpLogin":"toto","smtpPassword":"password","smtpSender":"toto"},
    "storageConfiguration" : {"RootDirectory":"/tmp/mdt"}
}

```

* ***serverListeningPort***:  Server Http port.
* ***serverExternalUrl***:  Server URL, used for installation links, upload python scripts and registration confirmation link.
* ***mongoServerUrl***:  MongoDB database location.
* ***storageMode***:  External storage used for artifact file. Values : FilesLocalStorage, TestingStorage
* ***storageConfiguration***:  External storage configuration, see External Storage configuration for info.
* ***smtpConfiguration***:  SMTP server configuration for emails (activation,...).
* ***registrationWhiteDomains***: Array of white suffix emails allowed for registration. If empty, no filter will be apply for registration.
* ***automaticRegistration***: 'true' if registration use a activation email to activate account.
* ***jwtSecretToken***: Secret used to secure links web token.
* ***logDirectory***: Log directory.
* ***initialAdminPassword***: Initial sysadmin password, created when no sysadmin present.
* ***initialAdminEmail***: Initial sysadmin email, created when no sysadmin present.
* ***loginResponseDelay***: Delay before handle each login request. It can be use to limit load of brut force attack.
* ***minimumPasswordStrength***: Minimum strength password required. [0,1,2,3,4] if crack time is less than [10\*\*2, 10\*\*4, 10\*\*6, 10\*\*8, Infinity]. See [xcvbnm] for more details.

[xcvbnm]: https://github.com/exitlive/xcvbnm


### External Storages 

MDT use mongoDB to store Users account, Applications and Artifact info but use a external storage for Artifact files (etc: .ipa, .apk).

There are currently 2 external storage managed by MDT.

#### Testing Storage

Yes storage is a fake storage wich respond always yes on storage requests en return always same file on get artifact file requests. It can be use for platform tests without install managed. 

Sample: 

```
cat Sources/App/Config/envs/development/config.json 

{
  ...
    "storageMode":"TestingStorage",
    "storageConfiguration":{},
  ...
 }
  
```
#### Local Storage

This storage uses a local directory to store Artifacts file. Usefull with a NAS directory or Docker volumes. It creates directory structure to store files.

Sample: 

```
cat Sources/App/Config/envs/development/config.json 

{
  ...
  "storageMode":"FilesLocalStorage",
  "storageConfiguration" : {"RootDirectory":"/<path>/mdt"},
  ...
 }
  
```

# Artifacts provisionning

Artifacts provisionning can be done either through UI web or ethier directly on a non authenticate REST Api, only application private apiKey is needed. Usefull for integration server.

See swagger for definition Apis

MDT provides a python script to help using artifact provisionning.

**Note**: You need requests python3 module installed to use it.

For help:

```
curl -Ls "http://localhost:8081\<config.pathPrefix>/v2/Artifacts/<application.apiKey>/deploy" | python3 - -h
```

Sample

```
From deploy input file:
	- version:
curl -Ls http://<myserver>/api/in/v1/artifacts/{apiKey}/deploy | python - ADD|DELETE fromFile sample.json

	- latest:
curl -Ls http://<myserver>/api/in/v1/artifacts/{apiKey}/deploy | python - ADD|DELETE --latest fromFile sample.json

cat sample.json
[{
    "branch":"master",
    "version":"X.Y.Z",
    "name":"dev",
     "file":"myGreatestApp_dev.ipa"
},{
    "branch":"master",
    "version":"X.Y.Z",
    "name":"prod",
     "file":"myGreatestApp.ipa"
},...]
Note : For latest deploy/delete somes unused values will be ignore.
Note: "file" path is relative from deployement file (sample.json in example)

From parameters:
	- version:
curl -Ls http://<myserver>/api/in/v1/artifacts/{apiKey}/deploy | python - ADD|DELETE fullParameters -version X.Y.Z -branch master -name prod -file app.apk|.ipa

	- latest:
curl -Ls http://<myserver>/api/in/v1/artifacts/{apiKey}/deploy | python - ADD|DELETE --latest fullParameters -name prod -file app.apk|.ipa


```

# Additional functionality

## Retrieve Max Version for specific branch


In order to allows application to check if a newer version is available, MDT provides a anonymous check to retrieve the max version on a application (regarding a provided branch and a version name).

The mechanism use here is a share secret between application and MDT server (each MDT application has his own secret) and a timestamped request.** The validity of a signed request is yet 30 secs (regarding the server date of course)**. 

To enable this functionality you have  Application propertie maxVersionCheckEnabled to True. 
next, AppId and AppSecret will be retrieved on next Application detail. 



MDT server Url :
    
    https://\<myserver\>/\<basePath\>/v2/Applications/\<ApplicationUuid\>/maxversion/<branch\>/\<version name\>?\<signed query\>
    
 Signed query format :
 
    "ts=" + currentMillisecondTimestampSince1970 +"&branch=" + branch + "&hash=" + hash
  
  Hash computation:
  
```   
  hash = md5("ts=" + currentMillisecondTimestampSince1970 +"&branch=" + branch + "&hash=" + appSecret) 
```

The result of the request as a format :

```

{
    "info": {
        "directLinkUrl": "<download link>", // direct link for max version artifact 
        "installPageUrl": "<http install page>", // Intall page with a brief of application and version and "install" button
        "validity": 3, //links validity in minutes
        "installUrl": "<install link>", // install link for max version artifact 
    },
    "name": "prod",
    "branch": "test",
    "version": "1.0.0"
}
```

Example:

```
Case of iOS Application

 appId = 33-343-4343
 appSecret = sqd*$/ùmzefmùqs
 branch = master
 name = prod
 
 currentMillisecondTimestampSince1970 = 122402423042342
 
 queryToSign format: "ts=" + currentMillisecondTimestampSince1970 +"&branch=" + branch + "&hash=" + appSecret
 
 md5("ts=122402423042342&branch=master&hash=sqd*$/ùmzefmùqs") =  "ed15111cfd7ec0674dc34a3ea8425907"
 
 finalQuery Format : "ts=" + currentMillisecondTimestampSince1970 +"&branch=" + branch + "&hash=" + md5
 query = "ts=122402423042342&branch=master&hash=ed15111cfd7ec0674dc34a3ea8425907"
 
 curl "ttps://\<myserver\>/\<basePath\>/v2/Applications/33-343-4343/maxversion/master/prod?ts=122402423042342&branch=master&hash=ed15111cfd7ec0674dc34a3ea8425907"
 
 >>> 
 
{
	"info": {
		"directLinkUrl": "https://.../file?token=7E5B930E-BA7F-4A84-9B4F-...",
		"installPageUrl": "https://.../install?token=7E5B930E-BA7F-4A84-9B4F-...",
		"validity": 3,
		"installUrl": "itms-services:\/\/?action=download-manifest&url=http://.../ios_plist?token%3D7E5B930E-BA7F-4A84-9B4F-..."
	},
	"name": "prod",
	"branch": "master",
	"version": "1.0.0"
}
 
```

# Why use MDT ?

* Unlike other solutions ([Fabrics], [TestFlight],...), you have no need to add all your users emails or manage groups to distribute your apps. Users can register themself (with white domains email configuration if needed) and access all your distributes apps. This is very usefull for example on IOS with 'InHouse' certificates in company where anybody can test beta versions of applications.

* You can delete artifacts, to avoid out of date versions (certificats expiration, bad versions, etc..)

* MDT have a special "latest" version usefull if you have continous testers: no need to make a new version after each fonctionality implemented.

* All your artifacts are stored in **your** storage area 


[Fabrics]: https://get.fabric.io
[TestFlight]: https://developer.apple.com/testflight/
  
### License

MDT is under the MIT license. See the [LICENSE](LICENSE) file for details.
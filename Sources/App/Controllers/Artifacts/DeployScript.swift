//
//  DeployScript.swift
//  App
//
//  Created by Rémi Groult on 24/11/2019.
//

import Foundation

func pythonDeployScript(apiKey:String, exernalServerHost:String) -> String {
    return """
    import argparse
    import urllib
    import urllib2
    import os
    import sys
    import json
    import requests

    serverHost = '\(exernalServerHost)'
    #apiKey='583fa4c2-8865-4229-b89b-c1d36683425d'
    apiKey='\(apiKey)'
    #how to use ex :curl -Ls http://localhost:8080/api/v2/artifacts/<api_key>/deploy | python - ADD fromFile sample.json

    def loadDeployInfoFromFile(filename) :
        print 'load deploy info from '+filename
        with open(filename) as json_data:
            jsonData = json.load(json_data)
            return jsonData

    def urlForParameters(isLatest,branch,version,name):
        if isLatest == True:
            return serverHost+'/v2/Artifacts/'+apiKey+'/latest/'+name
        else:
            if branch is None:
                print 'branch not defined'
                exit(404)
            elif version is None:
                print 'version not defined'
                exit(404)
            else:
                return serverHost+'/v2/Artifacts/'+apiKey+'/'+branch+'/'+version+'/'+name
            
    
    def get_content_type(filename):
        name, extension = os.path.splitext(filename)
        if extension and extension.lower() == '.ipa':
            return 'application/octet-stream ipa'

        if extension and extension.lower() == '.apk':
            return 'application/vnd.android.package-archive'
        
        return 'application/octet-stream'


    def postArtifact(isLatest,branch,version,name,filename):
        url = urlForParameters(isLatest,branch,version,name)
        print 'Artifact filename: ' + filename
        try:
            mimetype = get_content_type(filename)
            print('MimeType ' + mimetype)
            # file = {'artifactFile': (os.path.basename(filename), open(filename, 'rb'), 'application/octet-stream')}
            print 'send artifact '+os.path.basename(filename)+ ' to '+url
            #branch+'/'+version+'/'+name
            # print 'send artifact '+url
            data = open(filename, 'rb').read()
            r = requests.post(url=url,
                data=data,
                headers={'Content-Type': 'application/octet-stream','x-filename' : filename, 'x-mimetype' : mimetype})

           # r = requests.post(url, files=file)
            if r.status_code != 200:
                print 'Error on post Artifact:'+r.text
                return False
            else:
                return True
        except (requests.exceptions.RequestException,requests.packages.urllib3.exceptions.ProtocolError) as error :
            print 'error '+ repr(error)
            return False
        

    def deleteArtifact(isLatest,branch,version,name):
        url = urlForParameters(isLatest,branch,version,name)
        try:
            print 'delete artifact at /'+branch+'/'+version+'/'+name
            r = requests.delete(url)
            if r.status_code in [ 200, 404]:
                return True
            else:
                print 'Error on delete Artifact:'+r.text
                return False
        except (requests.exceptions.RequestException,requests.packages.urllib3.exceptions.ProtocolError) as error :
            print 'error '+ repr(error)
            return False
        


    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version', version='1.0.0')
    parser.add_argument("action", choices=["ADD", "DELETE"])
    parser.add_argument("--latest", action='store_true', help="deploy on latest version")
    subparsers = parser.add_subparsers(dest="inputType")

    inputFile = subparsers.add_parser('fromFile')
    inputFile.add_argument("filename", help="Input deployment json file")

    inputParameters = subparsers.add_parser('fullParameters')
    inputParameters.add_argument("-branch", help="Branch name(ex:master)")
    inputParameters.add_argument("-version", help="Artifact version (ex:1.2.3, ...)")
    inputParameters.add_argument("-name", help="Artifact name (ex:prodution, integration)",required=True)
    inputParameters.add_argument("-file", help="Artifact file (.IPA,.APK)")

    if __name__ == '__main__':
        args = parser.parse_args()
        print args
        print 'Command:'+args.inputType
        if args.inputType == 'fromFile':
            print 'Deploy from input values in file '+args.filename
            jsonData = loadDeployInfoFromFile(args.filename)
            print jsonData
            if type(jsonData).__name__ != 'list':
                jsonData = [jsonData]
            for data in jsonData:
                if args.action == 'ADD':
                    filePath = data['file']
                    if os.path.isabs(filePath) == False: # relative path
                        # concat file path to json file path
                        filePath = os.path.join(os.path.dirname(args.filename),filePath)
                    
                    postArtifact(args.latest,data['branch'],data['version'],data['name'],filePath)
                else:
                    deleteArtifact(args.latest,data['branch'],data['version'],data['name'])
        else :
            if args.action == 'ADD':
                postArtifact(args.latest,args.branch,args.version,args.name,args.file)
            else:
                deleteArtifact(args.latest,args.branch,args.version,args.name)

    '''
    Deploy file sample for full version
    {
        "branch":"master",
        "version":"X.Y.Z",
        "name":"dev",
         "file":"myGreatestApp_dev.ipa"
    },{
        "branch":"master",
        "version":"X.Y.Z",
        "name":"prod",
         "file":"myGreatestApp.ipa"
    },...

    Deploy minimal file sample for latest version
    Note: if a full version format is used, somes unused flags will be ignore
    {
        "name":"dev",
         "file":"myGreatestApp_dev.ipa"
    },{
        "name":"prod",
         "file":"myGreatestApp.ipa"
    },...

    '''

    #artifacts/{apiKey}/{branch}/{version}/{artifactName}')
    """
}

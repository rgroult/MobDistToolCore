//
//  InstallPage.swift
//  App
//
//  Created by Rémi Groult on 26/11/2019.
//

import Foundation
import Vapor

func generateInstallPage(for artifact:Artifact,into app:MDTApplication,installUrl:String) -> String {
    return """
<html>
<head>
    <title>OTA Installation</title>
    <style type="text/css">
    label { display: inline-block; width: 90px; text-align: left;}
    </style>
    <!-- Material Design fonts -->
  <link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Roboto:300,400,500,700">
  <link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/icon?family=Material+Icons">

  <!-- Bootstrap -->
  <link rel="stylesheet" type="text/css" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">

  <!-- Bootstrap Material Design -->
  <link rel="stylesheet" type="text/css" href="css/bootstrap-material-design.css">
  <link rel="stylesheet" type="text/css" href="css/ripples.min.css">
</head>
<body>
<style type="text/css">
    #finished { display: none; }
</style>
<div class="jumbotron">
    <div class="container">
        <div class="well bs-component">
            <h2>\(app.name) <img src="data:image/png;\(app.base64IconData)"/></h2>
            <h3>Version \(artifact.version) on branch \(artifact.branch)</h3>
            <br/>
            <p><a href="\(installUrl)" onclick="document.getElementById('finished').id = '';" class="btn btn-primary btn-raised btn-success">Install</a></p>
            <br/>
            <h3 id="invalid-device">Please open this page on your iOS or Android smartphone!</h3>

             <p id="finished">
                App is being installed. Close Safari using the home button.
            </p>
            <br/>
        </div>
    </div>
</div>
</body>
<script type='text/javascript'>
    if (/iPhone|iPod|Android/i.test(navigator.userAgent) && isIphoneValid() ) {
        showInstallLink();
      }

    function showInstallLink() {
      document.getElementById("invalid-device").remove();
    }
  </script>
</html>
"""
}

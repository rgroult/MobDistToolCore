Feature: Application Destruction
        Scenario: Application Empty
            Given A started server
            And Create a user and login
            And Create a sample iOS Application
            When I retrieve all applications, I can see 1 application(s)
            Then I delete sample iOS Application
            
        

Feature: Application Destruction
        Scenario: Application with artifacts

Feature: Application Destruction
        Scenario: Application with permanents links

        Given A started server
        And Create a user and login
        And Create a sample iOS Application
        And Upload sample artifact named "prod", version "1.0.0" on branch "master"
        When I create a permanent link for last version on branch master
        And I get iOS Application detail
        Then I can see 1 permanent link on iOS Application application detail
        And I can see a available version "1.0.0" in first permanent link
        And I can donwload artifact from first permanent link installUrl

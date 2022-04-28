Feature: Application Destruction
        Scenario: Application Empty
            Given A started server
            And Create a user and login
            And Create a sample iOS Application
            Then I retrieve all applications, I can see 1 application(s)
            When I delete sample iOS Application
            Then I retrieve all applications, I can see 0 application(s)

        Scenario: Application with artifacts
            Given A started server
            And Create a user and login
            And Create a sample iOS Application
            And Upload 10 artifact(s) named "prod", from prefix version "1.0" on branch "master"
            Then I retrieve all applications, I can see 1 application(s)
            And I retrieve all artifacts for current applications, I can see 10 artifact(s)
            When I delete sample iOS Application
            Then I retrieve all applications, I can see 0 application(s)
            And I count artifacts in database, I can see 0 artifact(s)
            
        Scenario: Application with permanents links
            Given A started server
            And Create a user and login
            And Create a sample iOS Application
            Then I create a permanent link for last version on branch "master"
            And I get iOS Application detail
            Then I can see 1 permanent link on iOS Application application detail
            When I delete sample iOS Application
            Then I retrieve all applications, I can see 0 application(s)
            And I count tokens in database, I can see 0 token(s)
            

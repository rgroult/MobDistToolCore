Feature: Permanent link
    Scenario: Create permanent link
        Given A started server
        And Create a user and login
        And Create a sample iOS Application
        And Upload Samples Artifacts and branch master
        When I create a permanent link for last version on branch master
        And I get iOS Applation detail
        Then I can see 1 permanent link on iOS Application application detail
        And I can see a available version in first permanent link

    Scenario: Test permanent link without artifact
        Given A started server
        And Create a user and login
        And Create a sample iOS Application
        When I create a permanent link for last version on branch master
        And I get iOS Applation detail
        Then I can't see any available version in first permanent link
        
    Scenario: Test permanent link with artifact
        Given A started server
        And Create a user and login
        And Create a sample iOS Application
        And Upload sample artifact named "prod", version "1.0.0" on branch "master"
        When I create a permanent link for last version on branch master
        And I get iOS Applation detail
        Then I can see 1 permanent link on iOS Application application detail
        And I can see a available version "1.0.0" in first permanent link
        And I can donwload artifact from first permanent link installUrl
        
Feature: Application Destruction
        Scenario: Application Empty

Feature: Application Destruction
        Scenario: Application with artifacts

Feature: Application Destruction
        Scenario: Application with permanents links

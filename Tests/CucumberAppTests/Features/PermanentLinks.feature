Feature: Permanent link
    Scenario: Create permanent link
        Given A started server
        And Create a user and login
        And Create a sample iOS Application
        And Upload Samples Artifacts and branch master
        When I create a permanent link for last version on branch master
        Then I can receive permanent link info

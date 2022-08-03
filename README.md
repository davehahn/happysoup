[![Production](https://github.com/Legend-Boats/HappySoup/actions/workflows/pr_deploy_to_production.yml/badge.svg)](https://github.com/Legend-Boats/HappySoup/actions/workflows/pr_deploy_to_production.yml)
[![Staging](https://github.com/Legend-Boats/HappySoup/actions/workflows/pr_deploy_to_staging.yml/badge.svg)](https://github.com/Legend-Boats/HappySoup/actions/workflows/pr_deploy_to_staging.yml)
[![Validate Develoment](https://github.com/Legend-Boats/HappySoup/actions/workflows/pr_develop.yml/badge.svg)](https://github.com/Legend-Boats/HappySoup/actions/workflows/pr_develop.yml)

# Legend Bug Fix Week Process (DEPRECATED)

### Step 1 - Setup dev and validation orgs

* Refresh your current dev org from Production or create a new one.  Once refreshed populate standard data and 
any other data you require using DumpIt. ( Ask Dave about this )
* Create a new validate sandbox from Production. This will be used to perform local test deploys/validations. Make note of what you named it.
* Authorize your newly created validation sandbox with sfdx giving it a alias of your choosing.  
``sfdx force:auth:web:login -a YOUR-VALIDATION-ORG-ALIAS -r https://test.salesforce.com``


### Step 2 - Setup git branch

* Create a LOCAL branch called {month}-bugsprint-{name} from staging.  We will refer to this as your "buxfix containing branch".    
``git checkout staging``     
``git checkout -b dec-bugsprint-dave`` 

### Step 3 - Update Source/Source Tracking on your dev org

* Perform a Local Push to ensure all code from the repository exists in your Dev org.  This will also update the Source Tracking of SFDX allow sfdx force:source:pull to function.  
``./local_push.sh YOUR_DEV_OR_ALIAS``

### Step 4 - Make your changes and commit
* It is now time to make the required changes to close the particular issue you are working on.
* If you have made declarative changes you can use the  Local Pull command to get those.  *note: this does not apply to static resources, if you update/created a static resource you will be required to manual retrieve and add it source.  
``./local_pull.sh YOUR_DEV_ORG_ALIAS``
* Please take a minute to review what this command retrieved.  If you do not recognize a piece of metadata that was retrieved, please do not commit it.
* Add all new files to source and commit ENSURING you reference the Jira Issue Number in the commit.  
``git add -A``  
``git commit -am 'closes SFISSUES-###'``  
* If you are working on a complex issue where you feel you will need to make several commits along the way, create a new issue specific branch off your bugfix containing branch.  
``git checkout -b SFISSUES-###``  
* make all your changes and commits.  
``git commit -am 'did some work'``  
``...``  
``...``  
``git commit -am 'did some more work'``
* when you are all done and made your final commit, make sure the final commit message contains reference to the Jira Issue name.  If you forgot simply run ``git commit --amend`` and edit the commit message to add the Jira Issue name.
* You can now merge your Issue specific branch into your bugfix containing branch.  
``git checkout YOUR-BUGFIX-CONTAININ-BRANCH``  
``git merge SFISSUES-###``
* It is best practice to push your bugfix containing branch up to Bitbucket after every Issue has been resolved, basically just for safe keeping.

### Step 5 (optional) - Local deploy validation

* If you have made large changes, especially large code changes, and you would like to validate your current bugfix containing branch run:  
``./local_deploy.sh YOUR-VALIDATION-ORG-ALIAS RunLocalTests true``
* This will perform a validation only deploy and run all unit tests, it will take awhile, but is very valuable.

### Step 6 - All Issues closed
* Once you perform all required changes to resolve all Jira issues assigned to you AND you have verified your local bugfix containing branch by performing Step 5, log into Bitbucket and create a Pull Request
into ``bugfix/{month}-sprint`` branch.  If this branch does not exist in Bitbucket, contact Dave and ask him nicely to get off his ass and create it.

### Step 7 - Celebrate, you are done.
* You have completed your bugfix sprint, congrates, doesn't feel good? Yes it does, jump up, shoot at the world "Screw you bugs, your DEAD", or maybe quietly have a drink when you get home and reflect at how awesome you are.

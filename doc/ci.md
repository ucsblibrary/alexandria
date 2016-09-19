# Continuous Integration

Before and after code is merged into the `master` branch, tests are
automatically run.  Currently we use Jenkins for testing PRs and for
running tests on the `master` branch itself.

The Jenkins instance is located on the private network at
<http://jenkins:8080/>, but tests aren’t run directly on the
Jenkins server.  Instead, it has worker VMs that it delegates jobs to.

## Jenkins configuration

### System configuration (<http://jenkins:8080/configure>)

- Under “Usage”, we’ve selected “Only build jobs with label
  expressions matching this node”; the Jenkins server doesn’t have
  PhantomJS installed and is not configured for running the RSpec
  tests.  We only use it for delegating to the worker VMs.

- Under “Global Slack Notifier Settings”, we just plug in the settings
  provided by the Jenkins CI plugin for Slack.  You don’t need to fill
  out the “Slack Webhook Settings” section of the Jenkins system
  configuration.

- Under “GitHub Pull Request Builder”, we’ve got the URL endpoint of
  our Enterprise API (not the github.com endpoint) and the credentials
  for connecting.

    Check “Auto-manage webhooks”; I’m not sure if this is strictly
    necessary, but during testing leaving it unchecked _seemed_ to
    cause Jenkins to fallback to polling GitHub periodically for new
    PRs instead of listening to webhooks.

### PR configuration (<http://jenkins:8080/job/ADRL_pull-requests/configure>)

This is a multi-configuration project, meaning we run the same job(s)
against a matrix of configuration.  For now we’re just testing against
Ruby 2.3.0 and 2.3.1.

- In “General”, check “GitHub project” and enter the URL (without the
  `.git`).  Also check “Rebuild Without Asking For Parameters”; this
  will allow us to re-run jobs without manually entering the commit to
  test.

    Check “This project is parameterized”.  The webhook that GitHub
    uses to notify Jenkins of changes involves a
    [request via curl](https://wiki.jenkins-ci.org/display/JENKINS/Git+plugin#GitPlugin-Pushnotificationfromrepository)
    containing a number of parameters; the one we’re interested in is
    the `sha1`.

- Under “Advanced Project Options”, check “Restrict where this project
    can be run” and restrict it to running on the master node (i.e.,
    the Jenkins server itself).  This project doesn’t actually involve
    running RSpec; rather, it delegates the jobs (with each
    configuration option) to an appropriate worker.

- Under “Source Code Management” select “Git” and put in the URL (with
    the `.git` this time) and credentials.  Click “Advanced” and add
    the
    [refspec](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec)
    so that PR commits are
    [made available](https://caffinc.github.io/2015/11/github-pr-revision/);
    we’re using `+refs/heads/master:refs/remotes/origin/master
    +refs/pull/*:refs/remotes/origin/pr/*`.

    Under “branches to build” put `${sha1}` instead, so we build the
    PR instead of a real branch.

    Under “Additional behaviors”, I added “Wipe out repository and
    force clone” just to make sure of a clean environment each time.

- Under “Build Triggers”, check “Build GitHub pull requests” and
  select “Hooks with Persisted Data” as the trigger mode.  For trigger
  events add “Pull request opened” and “Commit changed” (to detect
  force pushes to PRs).  The other settings are optional.

  Check “GitHub Pull Request Builder”, and add the credentials. Check
  “Use GitHub hooks for build triggering” and under “Advanced” check
  “Build every pull request automatically without asking
  (Dangerous!).”  Otherwise you’ll have to manually trigger builds
  from people who aren’t admins or whitelisted.

- Under “Configuration Matrix” we set the `RBENV_VERSION` environment
  variable by adding  a “User-defined Axis”.  The _Name_ is the env
  var and the _Values_ are space-separated values.

    Then to ensure these “downstream” jobs are only run on worker VMs
    and not on master, we add a “Slaves” matrix (ugh, I know).  Name
    it whatever you want, then select the appropriate machines under
    “Individual nodes”.

- Under “Build Environment”, check “rbenv build wrapper” so it
    installs ruby-build and everything, but just put in something for
    the ruby version since that field doesn’t take variables.  We’ll
    override it below.

- Under “Build”, use the `RBENV_VERSION` to make sure the right Ruby
    version is available before running tests (we don’t need `rbenv
    local`; rbenv respects the value of the environment variable).

    ```shell
    {
    if ! rbenv versions | grep "$RBENV_VERSION" >/dev/null 2>&1; then
      rbenv install $RBENV_VERSION
    fi

    gem install --no-document bundler rake
    bundle install --without=production development
    cp config/secrets.yml.template config/secrets.yml
    make spec
    }
    ```

### Master branch configuration (<http://jenkins:8080/job/ADRL_master/configure>)

This is just a simplified version of the PR project.  It’s not a
multi-configuration project, since we’re only testing against the
version of Ruby in production (currently 2.3.0).

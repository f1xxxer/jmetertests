# jmetertests
<H2>Distributed testing with JMeter and Azure Container Instances</H2>

To build Controller Docker image have a look and run <b>buildController.ps1</b> script.
To build Server\Worker Docker image have a look and run <b>buildServer.ps1</b> script.

Make sure that line endings in the <b>entrypointController.sh</b> and <b>entrypointServer.sh</b> are LF otherwisen containers will fail with error.

<b>bootstrap.ps1</b> is the main script that creates infrastructure and runs the tests.

<b>demo.jmx</b> is just a simple test for demonstration purposes.

P.S. don't forget to login into azure with 'az login' before running the script :)
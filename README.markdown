Dummy App
===

An app for testing running rails app inside docker containers.

instructions
---

1. git clone this repo into your /data directory of your ec2 instance.

2. cd into the cloned repo

3. build your app image

  ```bash
  $ docker build -t container_dummy .
  ```

4. create your postgresql container

  ```bash
  $ docker run -P --name db -d -t postgres:latest
  ```

5. create app container linked to postgres container

  ```bash
  docker run -d -p 80:80 --link db:postgres container_dummy
  ```

6. you're done, go to your ec2 instance ip to see app

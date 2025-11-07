# devops-intern-final

Hi! I'm **Nandish Hiremath** and this is my final DevOps intern project (November 2025). I built a tiny but complete workflow that touches Linux scripting, Git/GitHub, Docker, CI/CD with GitHub Actions, Nomad for deployment, and Grafana Loki + Promtail for monitoring.

I started by creating a very simple Python app and then wired it up across the stack. This helped me understand how each tool plays its part, from local scripts to containers, CI, and observability. I tested it locally and it worked fine. This was my first time trying Nomad, and it gave me a good idea of container orchestration.

## Overview
- **App:** `hello.py` prints a friendly message.
- **Script:** `scripts/sysinfo.sh` prints current user, date, and disk usage.
- **Container:** Minimal Docker image that runs the Python app.
- **CI:** GitHub Actions runs the Python app on every push/PR.
- **Deploy:** Nomad job to run the container as a service.
- **Monitoring:** Loki (logs) + Promtail (log shipper), optional Grafana UI.

## Project Structure
```
.
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── README.md
├── hello.py
├── scripts/
│   └── sysinfo.sh
├── nomad/
│   └── hello.nomad
└── monitoring/
    ├── loki_setup.txt
    └── promtail-config.yml
```

## Step 1: Git & GitHub
- Initialize and push:
```
git init
git add .
git commit -m "Initial commit: DevOps intern final"
# Create a GitHub repo named devops-intern-final, then:
git branch -M main
git remote add origin git@github.com:<your-username>/devops-intern-final.git
git push -u origin main
```

## Step 2: Linux & Shell Scripting
- Run the system info script:
```
chmod +x scripts/sysinfo.sh
./scripts/sysinfo.sh
```
It prints current user, date, and disk usage.

## Step 3: Docker
- Build and run the app container:
```
docker build -t hello-devops:latest .
docker run --rm hello-devops:latest
```

## Step 4: CI/CD with GitHub Actions
The workflow in `.github/workflows/ci.yml` runs on every push/PR:
- Checks out code
- Sets up Python 3.12
- Runs `python hello.py`

You should see the logs in GitHub Actions with the message output.

## Step 5: Nomad Deployment
- Make sure you have a Nomad agent running (dev mode is fine):
```
nomad agent -dev
```
- Run the job:
```
nomad job run nomad/hello.nomad
```
- Check status:
```
nomad job status hello-devops
```
The job uses the local Docker image tag `hello-devops:latest`.

## Step 6: Monitoring with Grafana Loki
- Quickstart using Docker (see `monitoring/loki_setup.txt`):
```
docker run -d --name loki -p 3100:3100 grafana/loki:2.9.8

docker run -d --name promtail \
  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
  -v $(pwd)/monitoring/promtail-config.yml:/etc/promtail/config.yml:ro \
  -p 9080:9080 \
  grafana/promtail:2.9.8 \
  -config.file=/etc/promtail/config.yml

curl -s "http://localhost:3100/ready"
```
- Optional: Run Grafana and add Loki as a data source at `http://localhost:3100`.

## What I Learned
- I started by creating the app and Dockerfile, which made the CI setup straightforward.
- This helped me understand how container images move from local builds to orchestration (Nomad).
- Setting up Promtail taught me how logs flow from containers into Loki.
- This was my first time trying Nomad, and it gave me a good idea of container orchestration.

## Optional Extension
- Try pushing the image to a registry (e.g., GHCR or Docker Hub) and updating Nomad to pull it.
- Add a simple dashboard in Grafana.
- Explore adding MLflow or deploying to a small VM.

## Final Thoughts
This repo captures a small, end-to-end DevOps loop I can build on. Feedback welcome!

import docker

slurm_image = 'giovtorres/docker-centos7-slurm:17.11.7'
client = docker.from_env()


client.pull(slurm_image)
client.run(slurm_image)
client.close()

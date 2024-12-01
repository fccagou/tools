## Convert gitlabci stages into Dockerfiles

### Why

Because it's boring to always write the same things !

### How

Using simple python script to parse yaml stages and generates Dockerfile for
each stage.

The first script was generated using standard [openai](https://openai.org).
It didn't work immediately but it's a quickly way to have a program template.

### Status

Actually is a draft process doing minimal.

### Quick start

Just run the script in the root dir of your project where `.gitlabci.yml` stands.

```bash
paython3 path/to/gitlabci-to-dockerfiles.py
```

The Dockerfiles are generated in current dir with name
`Dockerfile_{stage_name}_{job_name}`


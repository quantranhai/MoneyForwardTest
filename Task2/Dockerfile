FROM python:3.8-alpine

ADD samplecli.py /
RUN pip3 install -r requests==2.26.0
ENTRYPOINT [ "python", "./samplecli.py" ]
FROM khanlab/neuroglia-core:v1.5
MAINTAINER <alik@robarts.ca>


RUN mkdir /diffparcellate
COPY . /diffparcellate


#add path for root folder, deps, and mial-depends
ENV PATH /diffparcellate/mial-depends:/diffparcellate/deps:/diffparcellate:$PATH

#set below for runMatlabCmd
ENV PIPELINE_TOOL_DIR /diffparcellate

ENTRYPOINT ["/diffparcellate/run.sh"]

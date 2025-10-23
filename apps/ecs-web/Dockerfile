FROM public.ecr.aws/amazonlinux/amazonlinux:2023
RUN dnf -y install python3 && dnf clean all
COPY app.py /app/app.py
WORKDIR /app
EXPOSE 8080
CMD ["python3","app.py"]
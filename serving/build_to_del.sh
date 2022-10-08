cd final_solution_dev/serving/models/use_l/5.2 
wget https://tfhub.dev/google/universal-sentence-encoder-large/5?tf-hub-format=compressed -0 model.tar

tar -xvf model.tar
rm model.tar

docker run --rm -p 8501:8501 \
    --mount type=bind,source=$(pwd)/models/use_l,target=/models/use_l \
    -e MODEL_NAME=use_l -t tensorflow/serving:2.6.0

# docker pull tensorflow/serving:2.6.0
# curl http://localhost:8501/v1/models/use_l
# curl -d '{"instances": ["How you doing?"]}' -X POST http://167.235.136.60:8501/v1/models/use_l:predict
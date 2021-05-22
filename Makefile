ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

print:
	echo ${ROOT_DIR}

generate:
	mkdir -p generated1
	mkdir -p generated2
	mkdir -p generated3
	mkdir -p generated4
	mkdir -p generated5
	mkdir -p generated6
	mkdir -p generated7
	mkdir -p generated8
	mkdir -p generated9
	mkdir -p generated10
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated1 --temperature=0.1
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated2 --temperature=0.2
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated3 --temperature=0.3
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated4 --temperature=0.4
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated5 --temperature=0.5
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated6 --temperature=0.6
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated7 --temperature=0.7
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated8 --temperature=0.8
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated9 --temperature=0.9
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=10000 --output_dir=${ROOT_DIR}/generated10 --temperature=1.0

cat-drums_2bar_small.lokl.tar:
	wget https://storage.googleapis.com/magentadata/models/music_vae/checkpoints/cat-drums_2bar_small.lokl.tar

install: cat-drums_2bar_small.lokl.tar
	apt-get install libasound2-dev libjack0 libjack-dev
	python3 -m pip install magenta
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

print:
	echo ${ROOT_DIR}

generate:
	mkdir -p generated
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.1
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.2
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.3
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.4
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.5
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.6
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.7
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.8
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=0.9
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.0
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.1
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.2
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.3
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.4
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.5
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.6
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.7
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.8
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=1.9
	music_vae_generate --config=cat-drums_2bar_small --checkpoint_file=cat-drums_2bar_small.lokl.tar --mode=sample --num_outputs=500 --output_dir=${ROOT_DIR}/generated --temperature=2.0

cat-drums_2bar_small.lokl.tar:
	wget https://storage.googleapis.com/magentadata/models/music_vae/checkpoints/cat-drums_2bar_small.lokl.tar

install: cat-drums_2bar_small.lokl.tar
	apt-get install libasound2-dev libjack0 libjack-dev
	python3 -m pip install magenta
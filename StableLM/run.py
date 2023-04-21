import sys
import os
import argparse
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, StoppingCriteria, StoppingCriteriaList

def main(args):
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model)

    if not args.nohalf:
        model.half().cuda()

    class StopOnTokens(StoppingCriteria):
        def __call__(self, input_ids: torch.LongTensor, scores: torch.FloatTensor, **kwargs) -> bool:
            stop_ids = [50278, 50279, 50277, 1, 0]
            for stop_id in stop_ids:
                if input_ids[0][-1] == stop_id:
                    return True
            return False

    system_prompt = args.system

    prompt = f"{system_prompt}{args.user}"

    response = ""

    for i in range(0, len(prompt), args.chunk_size):
        chunk = prompt[i:i + args.chunk_size]
        inputs = tokenizer(chunk, return_tensors="pt").to("cuda")
        tokens = model.generate(
            **inputs,
            max_new_tokens=64,
            temperature=0.7,
            do_sample=True,
            stopping_criteria=StoppingCriteriaList([StopOnTokens()])
        )
        response += tokenizer.decode(tokens[0], skip_special_tokens=True)

        if args.clear:
            torch.cuda.empty_cache()
    
    print(response)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate text using a pretrained language model.")
    parser.add_argument("-s", "--system", required=True, help="System input as text or filename.")
    parser.add_argument("-u", "--user", required=True, help="User input as text or filename.")
    parser.add_argument("-nohalf", action="store_true", help="Disable model half-precision (FP16).")
    parser.add_argument("-c", "--chunk_size", type=int, default=64, help="Size of input chunks for processing.")
    parser.add_argument("-m", "--model", default="stabilityai/stablelm-tuned-alpha-7b", help="Pretrained model name or path.")
    parser.add_argument("-clear", action="store_true", help="Clear GPU cache after processing each chunk.")

    args = parser.parse_args()

    if os.path.isfile(args.system):
        with open(args.system, "r") as f:
            args.system = f.read()
    
    if os.path.isfile(args.user):
        with open(args.user, "r") as f:
            args.user = f.read()

    main(args)

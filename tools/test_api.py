import openai

openai.api_key = "EMPTY"
openai.base_url = "http://101.201.110.157:8000/v1/"

model = "chatglm3-6b-xft"
prompt = "Once upon a time"

# create a completion
completion = openai.completions.create(model=model, prompt=prompt, max_tokens=64)
# print the completion
print(prompt + completion.choices[0].text)

# create a chat completion
completion = openai.chat.completions.create(
model=model,
messages=[{"role": "user", "content": "请问你叫什么名字?"}]
)
# print the completion
print(completion.choices[0].message.content)
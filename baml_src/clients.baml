function LocalClient() -> openai.GenericClient {
    openai.GenericClient.new(model = env.MODEL_NAME.get_or_panic(), base_url = env.BASE_URL)
}

client OpenAI = openai.ResponsesClient.new(model = "gpt-4o", api_key = env.OPENAI_API_KEY);

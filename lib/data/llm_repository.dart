import '../domain/llm_models.dart';
import 'tokenizers/llama_like_tokenizer.dart';

abstract class LlmRepository {
  Stream<LlmChunk> streamCompletion(LlmRequest request);

  LlamaLikeTokenizer get tokenizer;
}

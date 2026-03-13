final Duration gameDuration = Duration(minutes: 1);
final Duration learnDuration = Duration(seconds: 5);
final String apiKey = '';
final bool debug = true;

const String prompt = '''
You are an Educational Content Creator. Your task is to analyze the provided document and generate a multiple-choice quiz that accurately reflects its specific subject matter.

Rules:

    Topic Adaptation: Identify the main subject (e.g., Biology, History, Mathematics) and generate questions ranging from basic facts to conceptual understanding.

    JSON Format: Output ONLY a valid JSON array. No conversational text.

    Schema: > [
      {
        "id": integer,
        "question": "string",
        "options": {
          "A": "string", 
          "B": "string", 
          "C": "string", 
          "D": "string"
        },
        "answer": "A, B, C, or D"
      }
    ]

    Quality: Ensure all distractors (wrong answers) are plausible based on the context of the document.

    Quantity: Generate 10 questions depending on the quantity of the content.  

''';

const String sample = '''
[
    {
        "id": 1,
        "question": "What is the primary persona assigned to the AI for this task?",
        "options": {
            "A": "Curriculum Designer",
            "B": "Educational Content Creator",
            "C": "Academic Researcher",
            "D": "Technical Instructor"
        },
        "answer": "B"
    },
    {
        "id": 2,
        "question": "According to the 'Topic Adaptation' rule, what is the required scope of the quiz questions?",
        "options": {
            "A": "Only basic facts",
            "B": "Only conceptual understanding",
            "C": "Ranging from basic facts to conceptual understanding",
            "D": "Primarily advanced theoretical applications"
        },
        "answer": "C"
    },
    {
        "id": 3,
        "question": "Which output format is strictly mandated by the instructions?",
        "options": {
            "A": "A Markdown document",
            "B": "A comma-separated values (CSV) list",
            "C": "A valid JSON array",
            "D": "A plain text conversational response"
        },
        "answer": "C"
    },
    {
        "id": 4,
        "question": "What is the specified range for the number of questions to be generated?",
        "options": {
            "A": "5 to 20",
            "B": "10 to 40",
            "C": "20 to 50",
            "D": "Exactly 30"
        },
        "answer": "B"
    },
    {
        "id": 5,
        "question": "In the provided JSON schema, what is the expected data type for the 'id' field?",
        "options": {
            "A": "string",
            "B": "float",
            "C": "integer",
            "D": "boolean"
        },
        "answer": "C"
    },
    {
        "id": 6,
        "question": "What is the requirement for 'distractors' (wrong answers) in the quiz?",
        "options": {
            "A": "They must be obviously false to avoid confusion.",
            "B": "They must be plausible based on the context of the document.",
            "C": "They should be taken from unrelated subject matters.",
            "D": "They must always include 'All of the above'."
        },
        "answer": "B"
    },
    {
        "id": 7,
        "question": "What is the specific rule regarding conversational text in the final output?",
        "options": {
            "A": "Include a brief introduction and conclusion.",
            "B": "Conversational text is allowed only in the 'question' field.",
            "C": "Output ONLY a valid JSON array; no conversational text.",
            "D": "Provide a summary of the analysis before the JSON."
        },
        "answer": "C"
    },
    {
        "id": 8,
        "question": "How are the multiple-choice options structured within each JSON object in the schema?",
        "options": {
            "A": "As a simple array of four strings",
            "B": "As a nested object with keys 'A', 'B', 'C', and 'D'",
            "C": "As a single string separated by commas",
            "D": "As four separate root-level fields"
        },
        "answer": "B"
    },
    {
        "id": 9,
        "question": "Which field in the JSON schema indicates the correct choice for the question?",
        "options": {
            "A": "correct_option",
            "B": "solution",
            "C": "answer",
            "D": "key"
        },
        "answer": "C"
    },
    {
        "id": 10,
        "question": "Which of the following subjects is explicitly listed as an example in the 'Topic Adaptation' rule?",
        "options": {
            "A": "Physics",
            "B": "Biology",
            "C": "Philosophy",
            "D": "Economics"
        },
        "answer": "B"
    }
]
''';

from flask import Flask, jsonify, request
from PyPDF2 import PdfReader
from nltk.tokenize import sent_tokenize
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import nltk 
from nltk.corpus import wordnet 
import os
import smtplib
import email
import imaplib
from email.header import decode_header
import spacy
from nltk.corpus import wordnet as wn
from flask import Flask, request, jsonify
import nltk
from nltk.tokenize import word_tokenize
from nltk.stem import WordNetLemmatizer
from nltk.corpus import wordnet as wn
from collections import Counter
import email
import imaplib
from email.header import decode_header


app = Flask(__name__)

EMAIL_ID = "xyz@gmail.com"  # Update with your email ID
PASSWORD = "pass"  # Put your password within quotes Password for the gmail app 

# Load English tokenizer, tagger, parser, NER, and word vectors
nlp = spacy.load("en_core_web_sm")


def expand_query_with_synonyms(query):
    """
    Expand the user's query with synonyms using WordNet.

    Args:
        query (str): User's search query.

    Returns:
        str: Expanded query with synonyms.
    """
    expanded_query = []
    doc = nlp(query)
    for token in doc:
        synonyms = set()
        for syn in wn.synsets(token.text):
            for lemma in syn.lemmas():
                synonyms.add(lemma.name())
        if synonyms:
            expanded_query.append(" OR ".join(synonyms))
        else:
            expanded_query.append(token.text)
    return " ".join(expanded_query)


def process_query(query):
    """
    Process the user's search query using NLP techniques.

    Args:
        query (str): User's search query.

    Returns:
        dict: Processed query containing extracted entities and keywords.
    """
    # Tokenize and process the query
    doc = nlp(query)

    # Extract entities (e.g., email IDs, dates)
    entities = [ent.text for ent in doc.ents if ent.label_ in ["PERSON", "DATE", "ORG", "GPE"]]

    # Extract keywords
    keywords = [token.text for token in doc if not token.is_stop and not token.is_punct]

    return {"entities": entities, "keywords": keywords}

def searchMail(mailbox, search_type, search_term):
    """
    Search mails by subject / author mail ID

    Args:
        mailbox (str): The mailbox to search (e.g., INBOX, Sent Mail, Drafts).
        search_type (str): Type of search (sender or subject).
        search_term (str): The term to search for (sender email ID or subject).

    Returns:
        list: List of dictionaries representing email search results.
    """
    M = None
    try:
        M = imaplib.IMAP4_SSL('imap.gmail.com', 993)
        M.login(EMAIL_ID, PASSWORD)

        if mailbox.lower() == "inbox":
            mailBoxTarget = "INBOX"
        elif mailbox.lower() == "sent":
            mailBoxTarget = '"[Gmail]/Sent Mail"'
        elif mailbox.lower() == "drafts":
            mailBoxTarget = '"[Gmail]/Drafts"'
        elif mailbox.lower() == "important":
            mailBoxTarget = '"[Gmail]/Important"'
        elif mailbox.lower() == "spam":
            mailBoxTarget = '"[Gmail]/Spam"'
        elif mailbox.lower() == "starred":
            mailBoxTarget = '"[Gmail]/Starred"'
        elif mailbox.lower() == "bin":
            mailBoxTarget = '"[Gmail]/Bin"'
        else:
            mailBoxTarget = "INBOX"

        M.select(mailBoxTarget)

        if search_type.lower() == "sender":
            status, messages = M.search(None, f'FROM "{search_term}"')
        elif search_type.lower() == "subject":
            status, messages = M.search(None, f'SUBJECT "{search_term}"')
        else:
            status, messages = M.search(None, f'SUBJECT "{search_term}"')

        if str(messages[0]) == "b''":
            return []

        msg_list = []
        for i in messages[0].split():
            msg_dict = {}
            res, msg = M.fetch(i, "(RFC822)")
            for response in msg:
                if isinstance(response, tuple):
                    msg = email.message_from_bytes(response[1])

                    subject, encoding = decode_header(msg["Subject"])[0]
                    if isinstance(subject, bytes):
                        subject = subject.decode(encoding)

                    From, encoding = decode_header(msg.get("From"))[0]
                    if isinstance(From, bytes):
                        From = From.decode(encoding)
                    FromArr = From.split()
                    FromName = " ".join(namechar for namechar in FromArr[0:-1])

                    msg_dict["subject"] = subject
                    msg_dict["from"] = FromName
                    msg_dict["sender_email"] = FromArr[-1]

                    if msg.is_multipart():
                        for part in msg.walk():
                            content_type = part.get_content_type()
                            content_disposition = str(part.get("Content-Disposition"))
                            try:
                                body = part.get_payload(decode=True).decode()
                            except:
                                pass

                            if content_type == "text/plain" and "attachment" not in content_disposition:
                                msg_dict["body"] = body

                    else:
                        content_type = msg.get_content_type()
                        body = msg.get_payload(decode=True).decode()
                        if content_type == "text/plain":
                            msg_dict["body"] = body

            msg_list.append(msg_dict)

        return msg_list

    except Exception as e:
        print("An error occurred:", e)
        return []

    finally:
        if M:
            M.close()
            M.logout()

@app.route('/searchMail', methods=['POST'])
def search_mail_api():
    """
    API endpoint to search emails.
    """
    data = request.json
    mailbox = data.get('mailbox')
    search_type = data.get('search_type')
    search_term = data.get('search_term')

    if not all([mailbox, search_type, search_term]):
        return jsonify({'error': 'Missing parameters'}), 400

    try:
        
        search_results = searchMail(mailbox, search_type, search_term)
        return jsonify(search_results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500



def sendMail(send_to, msg):
    """
    To send a mail
    """
    characters = send_to.split()
    concatenated_string = ''.join(characters)
    print(concatenated_string)
    concatenated_string = concatenated_string.replace('dot', '.')
    concatenated_string = concatenated_string.replace('attherate', '@')
    concatenated_string = concatenated_string.lower()
    print(concatenated_string)
    mail = smtplib.SMTP('smtp.gmail.com', 587)
    mail.ehlo()
    mail.starttls()
    mail.login(EMAIL_ID, PASSWORD)
    #for person in send_to:
        #print(person)
        #print(msg)
        #mail.sendmail(EMAIL_ID, person, msg)
    print(send_to)
    print(msg)
    mail.sendmail(EMAIL_ID, concatenated_string, msg)
    mail.close()


def getMailboxStatus():
    """
    Get mail counts of all folders in the mailbox
    """
    M = imaplib.IMAP4_SSL('imap.gmail.com', 993)
    M.login(EMAIL_ID, PASSWORD)

    mailbox_status = {}
    for i in M.list()[1]:
        l = i.decode().split(' "/" ')
        if l[1] == '"[Gmail]"':
            continue

        stat, total = M.select(f'{l[1]}')
        l[1] = l[1][1:-1]
        messages = int(total[0])
        mailbox_status[l[1]] = messages

    M.close()
    M.logout()

    return mailbox_status

dataset = [
    (["urgent", "meeting", "agenda", "discussion"], "meeting"),
    (["rescheduled", "meeting", "time", "change"], "meeting"),
    (["payment", "overdue", "notice", "invoice", "unpaid"], "finance"),
    (["product", "launch", "announcement", "release", "new"], "marketing"),
    (["quarterly", "financial", "report", "review", "analysis"], "finance"),
    (["team", "building", "event", "invitation", "social", "gathering"], "social"),
    (["customer", "satisfaction", "survey", "feedback", "opinion"], "feedback"),
    (["performance", "review", "reminder", "evaluation"], "work"),
    (["holiday", "office", "closure", "notice", "shutdown"], "administrative"),
    (["project", "status", "update", "progress", "development"], "work"),
    (["training", "session", "registration", "confirmation", "signup"], "training"),
    (["network", "maintenance", "notification", "downtime", "outage"], "technical"),
    (["upcoming", "conference", "registration", "event", "symposium"], "conference"),
    (["employee", "benefits", "update", "insurance", "perks"], "HR"),
    (["company", "policy", "changes", "updates", "revisions"], "policy"),
    (["product", "recall", "notice", "defective", "withdrawal"], "quality"),
    (["discount", "code", "loyal", "customers", "promotion", "offer"], "sales"),
    (["invitation", "industry", "conference", "seminar", "forum"], "conference"),
    (["new", "feature", "release", "announcement", "update"], "product"),
    (["monthly", "team", "meeting", "agenda", "discussion"], "meeting"),
    (["celebration", "company", "milestone", "achievement", "success"], "milestone"),
    (["assignment", "submission", "reminder", "due", "deadline"], "assignment"),
    (["internship", "opportunity", "announcement", "placement"], "internship"),
    (["student", "club", "meeting", "invitation", "group"], "student"),
    (["academic", "advisor", "appointment", "confirmation", "schedule"], "academic"),
    (["student", "organization", "event", "announcement", "activity"], "student"),
    (["course", "registration", "deadline", "reminder", "enrollment"], "academic"),
    (["research", "project", "collaboration", "proposal", "partnership"], "research"),
    (["career", "fair", "registration", "details", "job"], "career"),
    (["mentoring", "program", "sign-up", "guidance", "support"], "mentoring"),
    (["student", "housing", "information", "accommodation", "residence"], "housing"),
    (["job", "interview", "scheduling", "appointment", "recruitment"], "interview"),
    (["student", "scholarship", "application", "deadline", "financial aid"], "scholarship"),
    (["competition", "announcement", "prize", "winners", "challenge"], "competition"),
]


# Tokenization
def tokenize(text):
    return word_tokenize(text)


# Lemmatization using WordNet
def lemmatize(tokens):
    lemmatizer = WordNetLemmatizer()
    lemmas = [lemmatizer.lemmatize(token, get_wordnet_pos(token)) for token in tokens]
    return lemmas


def get_wordnet_pos(word):
    """Map POS tag to first character lemmatize() accepts"""
    tag = nltk.pos_tag([word])[0][1][0].upper()
    tag_dict = {"J": wn.ADJ,
                "N": wn.NOUN,
                "V": wn.VERB,
                "R": wn.ADV}
    return tag_dict.get(tag, wn.NOUN)


def classify_email(email_data, dataset):
    email_body = email_data.get('body', '')
    # Tokenization and lemmatization
    tokens = tokenize(email_body.lower())
    lemmas = lemmatize(tokens)

    # Check if any lemma matches with keywords in the dataset
    matched_topics = []
    for lemma in lemmas:
        for keywords, topic in dataset:
            if any(keyword in lemma for keyword in keywords):
                matched_topics.append(topic)

    # Count the occurrences of each matched topic
    topic_counts = Counter(matched_topics)

    # Determine the most common topic
    if topic_counts:
        most_common_topic = topic_counts.most_common(1)[0][0]
        return most_common_topic
    else:
        return "Unknown"

def searchLatestMails():
    """
    Get latest mails from folders in mailbox (Defaults to 3 Inbox mails)
    """
    mail_box_target = "INBOX"

    imap = imaplib.IMAP4_SSL("imap.gmail.com")
    imap.login(EMAIL_ID, PASSWORD)

    status, messages = imap.select(mail_box_target)

    messages = int(messages[0])

    latest_mails = []
    if messages > 0:
        N = min(messages, 3)

        for i in range(messages, messages - N, -1):
            res, msg = imap.fetch(str(i), "(RFC822)")

            for response in msg:
                if isinstance(response, tuple):
                    msg = email.message_from_bytes(response[1])

                    mail_data = {}

                    subject, encoding = decode_header(msg["Subject"])[0]
                    if isinstance(subject, bytes):
                        subject = subject.decode(encoding)

                    From, encoding = decode_header(msg.get("From"))[0]
                    if isinstance(From, bytes):
                        From = From.decode(encoding)

                    mail_data['subject'] = subject
                    mail_data['from'] = From

                    if msg.is_multipart():
                        for part in msg.walk():
                            content_type = part.get_content_type()
                            content_disposition = str(part.get("Content-Disposition"))
                            try:
                                body = part.get_payload(decode=True).decode()
                            except:
                                pass

                            if content_type == "text/plain" and "attachment" not in content_disposition:
                                mail_data['body'] = body

                    else:
                        content_type = msg.get_content_type()
                        body = msg.get_payload(decode=True).decode()
                        if content_type == "text/plain":
                            mail_data['body'] = body

                    latest_mails.append(mail_data)
    # for m in latest_mails:
    # print(m)
    imap.close()
    imap.logout()

    return latest_mails

def getLatestMails():
    """
    Get latest mails from folders in mailbox (Defaults to 3 Inbox mails)
    """
    mail_box_target = "INBOX"

    imap = imaplib.IMAP4_SSL("imap.gmail.com")
    imap.login(EMAIL_ID, PASSWORD)

    status, messages = imap.select(mail_box_target)

    messages = int(messages[0])

    latest_mails = []
    if messages > 0:
        N = min(messages, 3)

        for i in range(messages, messages - N, -1):
            res, msg = imap.fetch(str(i), "(RFC822)")

            for response in msg:
                if isinstance(response, tuple):
                    msg = email.message_from_bytes(response[1])

                    mail_data = {}

                    subject, encoding = decode_header(msg["Subject"])[0]
                    if isinstance(subject, bytes):
                        subject = subject.decode(encoding)

                    From, encoding = decode_header(msg.get("From"))[0]
                    if isinstance(From, bytes):
                        From = From.decode(encoding)

                    mail_data['subject'] = subject
                    mail_data['from'] = From

                    if msg.is_multipart():
                        for part in msg.walk():
                            content_type = part.get_content_type()
                            content_disposition = str(part.get("Content-Disposition"))
                            try:
                                body = part.get_payload(decode=True).decode()
                            except:
                                pass

                            if content_type == "text/plain" and "attachment" not in content_disposition:
                                mail_data['body'] = body

                    else:
                        content_type = msg.get_content_type()
                        body = msg.get_payload(decode=True).decode()
                        if content_type == "text/plain":
                            mail_data['body'] = body

                    latest_mails.append(mail_data)
    # for m in latest_mails:
    # print(m)
    imap.close()
    imap.logout()

    return latest_mails


#emails = getLatestMails()
# Test the classifier with sample email bodies
'''for email_body in emails:
    topic = classify_email(email_body, dataset)
    print()
    print(f"Email body: {email_body} | Predicted topic: {topic}")'''


@app.route('/sendMail', methods=['POST'])
def send_mail_api():
    """
    API endpoint to send a mail
    """
    data = request.json
    send_to = data.get('sendTo')
    msg = data.get('msg')

    if not send_to or not msg:
        return jsonify({'error': 'Missing required parameters'}), 400

    try:
        sendMail(send_to, msg)
        return jsonify({'message': 'Mail sent successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/getMailBoxStatus', methods=['GET'])
def get_mailbox_status_api():
    """
    API endpoint to get mailbox status
    """
    try:
        mailbox_status = getMailboxStatus()
        return jsonify(mailbox_status), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/classify',methods = ['GET'])
def classify():
    latest_mails = getLatestMails()
    topics = {}
    for email_body in latest_mails:
        topic = classify_email(email_body, dataset)
        if topic not in topics:
            topics[topic] = [email_body]  
        else:
            topics[topic].append(email_body)  
    print(topics)
    return jsonify(topics)

@app.route('/getLatestMails', methods=['GET'])
def get_latest_mails_api():
    """
    API endpoint to get the latest mails
    """
    try:
        latest_mails = getLatestMails()
        topics = []
        for email_body in latest_mails:
            topic = classify_email(email_body, dataset)
            topics.append(topic)
        return jsonify({'latest_mails':latest_mails,'topics':topics}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def get_synonyms(word):
    synonyms = []
    for syn in wordnet.synsets(word):
        for l in syn.lemmas():
            synonyms.append(l.name())
    
    print(set(synonyms))
    return list(set(synonyms))

@app.route('/api/get_synonyms', methods=['GET'])
def api_get_synonyms():
    word = request.args.get('word')
    synonyms = get_synonyms(word)
    return jsonify({'synonyms': synonyms})

def summarize(text):
    sentences = sent_tokenize(text)
    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(sentences)
    sentence_similarity_matrix = cosine_similarity(tfidf_matrix, tfidf_matrix)

    scores = np.sum(sentence_similarity_matrix, axis=1)
    percentage_of_sentences = 0.5
    N = max(1, int(len(sentences) * percentage_of_sentences))
    summary_sentences = [sentences[i] for i in np.argsort(scores)[::-1][:N]]
    summary = ' '.join(summary_sentences)

    #print(summary)
    return summary


@app.route('/api', methods=['GET'])
def hello_world():
    d = {}
    d['Query'] = str(request.args['Query'])
    #print(d['Query'])
    summary=summarize(d['Query'])
    print(summary)
    return jsonify(summary)

@app.route('/api/data', methods=['GET'])
def get_data():
    data = {'message': 'Hello from Python backend!'}
    return jsonify(data)




if __name__ == '__main__':
    app.run(debug=True)

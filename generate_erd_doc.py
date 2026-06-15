import urllib.request
import urllib.parse
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.section import WD_ORIENT

def generate_erd_image():
    dot = """
    digraph ERD {
        graph [rankdir=TB, pad="1", nodesep="1", ranksep="2", splines=ortho, fontname="Helvetica", dpi=300];
        node [shape=none, fontname="Helvetica", fontsize=16];
        edge [fontname="Helvetica", fontsize=14, dir=both, arrowtail=crow, arrowhead=none, color="#555555"];

        subgraph cluster_core {
            label="Core Entities";
            fontsize=20;
            style=filled;
            color=lightgrey;
            fillcolor="#f9f9f9";

            users [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="8">
                <tr><td bgcolor="#4CAF50"><font color="white"><b>users</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">name</td></tr>
                <tr><td align="left">email</td></tr>
                <tr><td align="left">role</td></tr>
            </table>>];

            associations [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="8">
                <tr><td bgcolor="#2196F3"><font color="white"><b>associations</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">creator_id (FK)</td></tr>
                <tr><td align="left">name</td></tr>
            </table>>];

            circles [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="8">
                <tr><td bgcolor="#FF9800"><font color="white"><b>circles</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">association_id (FK)</td></tr>
                <tr><td align="left">created_by (FK)</td></tr>
                <tr><td align="left">name</td></tr>
            </table>>];
        }

        subgraph cluster_posts {
            label="Posts & Content";
            fontsize=20;
            style=filled;
            color=lightgrey;
            fillcolor="#f4f4f4";

            posts [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#9C27B0"><font color="white"><b>posts</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">user_id (FK)</td></tr>
                <tr><td align="left">association_id (FK)</td></tr>
            </table>>];

            post_likes [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#9C27B0"><font color="white"><b>post_likes</b></font></td></tr>
                <tr><td align="left"><u>post_id (FK)</u></td></tr>
                <tr><td align="left"><u>user_id (FK)</u></td></tr>
            </table>>];

            post_comments [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#9C27B0"><font color="white"><b>post_comments</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">post_id (FK)</td></tr>
                <tr><td align="left">user_id (FK)</td></tr>
            </table>>];

            post_shares [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#9C27B0"><font color="white"><b>post_shares</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">post_id (FK)</td></tr>
                <tr><td align="left">shared_by (FK)</td></tr>
            </table>>];
        }

        subgraph cluster_chat {
            label="Messaging";
            fontsize=20;
            style=filled;
            color=lightgrey;
            fillcolor="#eef2f3";

            conversations [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#E91E63"><font color="white"><b>conversations</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">created_by (FK)</td></tr>
            </table>>];

            conversation_members [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#E91E63"><font color="white"><b>conversation_members</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">conversation_id (FK)</td></tr>
                <tr><td align="left">user_id (FK)</td></tr>
            </table>>];

            messages [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#E91E63"><font color="white"><b>messages</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">conversation_id (FK)</td></tr>
                <tr><td align="left">sender_id (FK)</td></tr>
            </table>>];

            chat_invitations [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#E91E63"><font color="white"><b>chat_invitations</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">sender_id (FK)</td></tr>
                <tr><td align="left">receiver_id (FK)</td></tr>
            </table>>];
        }

        subgraph cluster_relations {
            label="Relations & Sub-entities";
            fontsize=20;
            style=filled;
            color=lightgrey;
            fillcolor="#fffde7";

            association_members [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#795548"><font color="white"><b>association_members</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">association_id (FK)</td></tr>
                <tr><td align="left">user_id (FK)</td></tr>
            </table>>];

            circle_members [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#795548"><font color="white"><b>circle_members</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">circle_id (FK)</td></tr>
                <tr><td align="left">user_id (FK)</td></tr>
            </table>>];

            meetings [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#795548"><font color="white"><b>meetings</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">circle_id (FK)</td></tr>
                <tr><td align="left">created_by (FK)</td></tr>
            </table>>];

            user_blocks [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#795548"><font color="white"><b>user_blocks</b></font></td></tr>
                <tr><td align="left"><u>blocker_id (FK)</u></td></tr>
                <tr><td align="left"><u>blocked_id (FK)</u></td></tr>
            </table>>];

            circle_access_requests [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#795548"><font color="white"><b>circle_access_requests</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">circle_id (FK)</td></tr>
                <tr><td align="left">user_id (FK)</td></tr>
            </table>>];

            circle_photos [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#795548"><font color="white"><b>circle_photos</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">circle_id (FK)</td></tr>
                <tr><td align="left">user_id (FK)</td></tr>
            </table>>];

            member_invitations [label=<<table border="0" cellborder="1" cellspacing="0" cellpadding="6">
                <tr><td bgcolor="#795548"><font color="white"><b>member_invitations</b></font></td></tr>
                <tr><td align="left"><u>id (PK)</u></td></tr>
                <tr><td align="left">association_id (FK)</td></tr>
                <tr><td align="left">invited_by (FK)</td></tr>
            </table>>];
        }

        // Relationships (Core)
        users -> associations [label="1:N"];
        users -> circles [label="1:N"];
        associations -> circles [label="1:N"];
        
        // Members
        users -> association_members [label="1:N"];
        associations -> association_members [label="1:N"];
        users -> circle_members [label="1:N"];
        circles -> circle_members [label="1:N"];
        
        // Posts
        users -> posts [label="1:N"];
        associations -> posts [label="1:N"];
        users -> post_likes [label="1:N"];
        posts -> post_likes [label="1:N"];
        users -> post_comments [label="1:N"];
        posts -> post_comments [label="1:N"];
        users -> post_shares [label="1:N"];
        posts -> post_shares [label="1:N"];
        
        // Chat
        users -> chat_invitations [label="1:N"];
        users -> conversations [label="1:N"];
        users -> conversation_members [label="1:N"];
        conversations -> conversation_members [label="1:N"];
        users -> messages [label="1:N"];
        conversations -> messages [label="1:N"];
        
        // Others
        users -> meetings [label="1:N"];
        circles -> meetings [label="1:N"];
        users -> user_blocks [label="1:N"];
        users -> circle_access_requests [label="1:N"];
        circles -> circle_access_requests [label="1:N"];
        users -> circle_photos [label="1:N"];
        circles -> circle_photos [label="1:N"];
        users -> member_invitations [label="1:N"];
        associations -> member_invitations [label="1:N"];
    }
    """
    
    # Request a massive, high-DPI image via API
    url = "https://quickchart.io/graphviz?graph=" + urllib.parse.quote(dot) + "&format=png"
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open("database_erd.png", 'wb') as out_file:
            data = response.read()
            out_file.write(data)
        print("Success! Downloaded high-res database_erd.png")
    except Exception as e:
        print("Error downloading ERD image:", e)


def add_heading(doc, text, level=1):
    heading = doc.add_heading(text, level=level)
    for run in heading.runs:
        run.font.color.rgb = RGBColor(0, 51, 102)

def create_word_document():
    doc = Document()
    
    # Title
    title = doc.add_paragraph('Database Schema Documentation')
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in title.runs:
        run.font.size = Pt(28)
        run.bold = True
        run.font.color.rgb = RGBColor(0, 51, 102)
        
    subtitle = doc.add_paragraph('Bantou Application - Complete Entity Relationship Specification')
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in subtitle.runs:
        run.font.size = Pt(16)
        run.italic = True
        
    doc.add_page_break()

    # 1. Overview
    add_heading(doc, '1. Database Overview', level=1)
    doc.add_paragraph(
        "This document presents the complete relational database schema currently implemented in the Bantou application. "
        "The database is designed to handle users, professional associations, circles (groups), posts, comments, real-time messaging, "
        "and meeting schedules. The system utilizes standard relational design principles with clearly defined foreign keys, constraints, "
        "and optimized junction tables for many-to-many relationships."
    )
    
    doc.add_paragraph("")
    
    # 2. Entity Relationship Diagram (Landscape Section)
    add_heading(doc, '2. Entity-Relationship Diagram (ERD)', level=1)
    doc.add_paragraph("The diagram below illustrates the comprehensive structure of the database, categorized into distinct functional modules (Core, Content, Chat, and Relations) for enhanced readability.")
    
    # Change orientation to landscape for the diagram page
    current_section = doc.sections[-1]
    new_width, new_height = current_section.page_height, current_section.page_width
    current_section.orientation = WD_ORIENT.LANDSCAPE
    current_section.page_width = new_width
    current_section.page_height = new_height
    
    try:
        # Increase width so it uses more of the landscape page, making it much more visible
        doc.add_picture('database_erd.png', width=Inches(9.5))
        img_para = doc.paragraphs[-1]
        img_para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    except Exception as e:
        doc.add_paragraph(f"[Image placeholder: ERD generation failed. {e}]")
        
    # Revert to Portrait for the next section
    doc.add_section()
    next_section = doc.sections[-1]
    next_section.orientation = WD_ORIENT.PORTRAIT
    next_section.page_width, next_section.page_height = next_section.page_height, next_section.page_width

    # 3. Table Descriptions
    add_heading(doc, '3. Table Descriptions', level=1)
    
    tables = [
        ("users", "Central entity storing all user accounts, authentication credentials (passwords/OAuth IDs), roles, statuses, and extended professional profile information (bio, city, job_title)."),
        ("associations", "Represents organizations or communities created by a user. Contains physical address, contact information, social links, and the association's logo."),
        ("circles", "Sub-groups or sub-communities belonging to a specific association. Contains details regarding responsible leaders, meeting locations, and planning info."),
        ("association_members", "Junction table mapping the Many-to-Many relationship between 'users' and 'associations', representing approved membership within an association."),
        ("circle_members", "Junction table representing users who are officially part of a specific circle."),
        ("circle_access_requests", "Tracks pending, approved, or rejected requests from users aiming to join a specific circle."),
        ("member_invitations", "Manages external or internal invitations sent to users (via email) to join a specific association or circle."),
        ("meetings", "Represents events or scheduled gatherings organized within a specific circle, including start and end times."),
        ("posts", "Content entities (text, images) created by users within the scope of a specific association. Includes denormalized counter columns for likes and comments."),
        ("post_likes", "Junction table tracking which users have liked which posts (Many-to-Many)."),
        ("post_comments", "Stores textual comments made by users on specific posts."),
        ("post_shares", "Tracks the re-sharing of posts from one user to another within the platform."),
        ("conversations", "Represents a chat thread (either direct private messaging or group messaging)."),
        ("conversation_members", "Junction table linking users to conversations, allowing group chats and defining participant roles (e.g., admin, member)."),
        ("messages", "Stores individual text messages or image payloads sent by a user within a conversation."),
        ("chat_invitations", "Tracks friend/connection requests sent between two users to initiate private messaging."),
        ("user_blocks", "Junction table representing a user blocking another user, utilized for privacy and security purposes."),
        ("circle_photos", "Stores URLs of photos uploaded specifically to a circle's gallery.")
    ]
    
    for table_name, description in tables:
        add_heading(doc, table_name.capitalize(), level=2)
        doc.add_paragraph(description)
        
    doc.add_page_break()

    # 4. Core Relationships
    add_heading(doc, '4. Core Relationships & Constraints', level=1)
    
    rels = [
        ("Users (1) - (N) Associations", "A single user can create multiple associations. Monitored via 'associations.creator_id' (FK)."),
        ("Associations (1) - (N) Circles", "An association is comprised of multiple circles. Monitored via 'circles.association_id' (FK)."),
        ("Users (N) - (M) Associations", "Users can join multiple associations, and associations have many users. Resolved by the 'association_members' table."),
        ("Users (N) - (M) Circles", "Users can join multiple circles. Resolved by the 'circle_members' table and regulated by 'circle_access_requests'."),
        ("Users (1) - (N) Posts", "A user can author multiple posts. 'posts.user_id' strictly enforces this ownership."),
        ("Associations (1) - (N) Posts", "A post always belongs to an association wall/feed. Enforced by 'posts.association_id'."),
        ("Posts (N) - (M) Users (Likes)", "A post can have many likes, and a user can like many posts. Handled by the composite primary key (post_id, user_id) in 'post_likes'."),
        ("Conversations (N) - (M) Users", "A conversation can have multiple participants. Handled by 'conversation_members'."),
        ("Conversations (1) - (N) Messages", "A conversation thread contains multiple messages, associated via 'messages.conversation_id'.")
    ]
    
    for rel_title, rel_desc in rels:
        p = doc.add_paragraph()
        run = p.add_run(f"• {rel_title}: ")
        run.bold = True
        p.add_run(rel_desc)

    # Save
    doc.save('Bantou_Database_Schema_v2.docx')
    print("Successfully generated Bantou_Database_Schema_v2.docx with Landscape High-Res ERD")

if __name__ == "__main__":
    generate_erd_image()
    create_word_document()

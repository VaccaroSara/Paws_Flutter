import xml.etree.ElementTree as ET

def create_nav_drawio_clean():
    mxfile = ET.Element('mxfile', {
        'host': 'Electron',
        'modified': '2026-08-20T12:25:00.000Z',
        'agent': 'Mozilla/5.0',
        'version': '21.6.8',
        'type': 'device'
    })
    
    diagram = ET.SubElement(mxfile, 'diagram', {
        'id': 'flutter-paws-nav',
        'name': 'Avvio e Navigazione Flutter Paws'
    })
    
    graph_model = ET.SubElement(diagram, 'mxGraphModel', {
        'dx': '1200',
        'dy': '900',
        'grid': '1',
        'gridSize': '10',
        'guides': '1',
        'tooltips': '1',
        'connect': '1',
        'arrows': '1',
        'fold': '1',
        'page': '1',
        'pageScale': '1',
        'pageWidth': '1200',
        'pageHeight': '800',
        'math': '0',
        'shadow': '0'
    })
    
    root = ET.SubElement(graph_model, 'root')
    
    # Base cells
    ET.SubElement(root, 'mxCell', {'id': '0'})
    ET.SubElement(root, 'mxCell', {'id': '1', 'parent': '0'})
    
    def add_node(node_id, label, x, y, width, height, style, parent='1'):
        cell = ET.SubElement(root, 'mxCell', {
            'id': node_id,
            'value': label,
            'style': style,
            'parent': parent,
            'vertex': '1'
        })
        ET.SubElement(cell, 'mxGeometry', {
            'x': str(x),
            'y': str(y),
            'width': str(width),
            'height': str(height),
            'as': 'geometry'
        })
        return cell

    def add_edge(edge_id, source, target, label='', style=None):
        if style is None:
            style = "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=classic;endWidth=6;endSize=6;strokeColor=#000000;strokeWidth=1;fontSize=10;"
        cell = ET.SubElement(root, 'mxCell', {
            'id': edge_id,
            'value': label,
            'style': style,
            'parent': '1',
            'edge': '1',
            'source': source,
            'target': target
        })
        ET.SubElement(cell, 'mxGeometry', {'relative': '1', 'as': 'geometry'})
        return cell

    # Outer Frame & Badge
    outer_style = "rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#99B898;strokeWidth=1.5;verticalAlign=top;align=left;"
    badge_style = "shape=label;html=1;fillColor=#D5E8D4;strokeColor=#82B366;fontStyle=1;fontSize=11;fontColor=#000000;align=center;verticalAlign=middle;rounded=0;"
    
    add_node('frame_outer', '', 30, 30, 1140, 730, outer_style)
    add_node('badge_nav', 'AVVIO E NAVIGAZIONE', 30, 30, 170, 30, badge_style)

    # Styles matching reference image colors
    style_orange = "rounded=0;whiteSpace=wrap;html=1;fillColor=#FFE6CC;strokeColor=#D79B00;fontColor=#000000;fontSize=12;align=center;verticalAlign=middle;"
    style_green = "rounded=0;whiteSpace=wrap;html=1;fillColor=#D5E8D4;strokeColor=#82B366;fontColor=#000000;fontSize=12;align=center;verticalAlign=middle;"
    style_purple = "rounded=0;whiteSpace=wrap;html=1;fillColor=#E1D5E7;strokeColor=#9673A6;fontColor=#000000;fontSize=12;align=center;verticalAlign=middle;"
    style_pink = "rounded=0;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;fontColor=#000000;fontSize=12;fontStyle=1;align=center;verticalAlign=middle;"
    style_rhombus = "rhombus;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;fontColor=#000000;fontSize=11;align=center;verticalAlign=middle;"

    # 1. Entry Point
    add_node('node_main', 'File\nmain.dart', 480, 50, 120, 55, style_orange)
    add_node('node_splash', 'Class\nSplashScreen', 465, 135, 150, 55, style_green)

    # 2. Auth Decision Rhombus
    add_node('node_auth_check', 'Verifica Sessione\ncurrentUser != null?', 445, 220, 190, 65, style_rhombus)

    # 3. Left Branch: Auth Flow (User Not Authenticated)
    add_node('node_signin', 'Class\nSignInScreen', 180, 225, 140, 55, style_green)
    add_node('node_signup', 'Class\nSignUpScreen', 180, 315, 140, 55, style_green)
    add_node('node_firebase_auth', 'FirebaseAuth\n(Login / Register)', 40, 270, 115, 55, style_pink)

    # 4. Right Branch: Main App Navigation Container (Authenticated)
    add_node('node_main_screen', 'Class\nMainScreen', 465, 340, 150, 55, style_green)
    add_node('node_bottom_bar', 'Util\nBottomNavigationBar\n(IndexedStack)', 455, 425, 170, 55, style_purple)

    # 5. Bottom Navigation Tabs (4 Tabs)
    add_node('node_home_tab', 'Class\nHomeTab\n(Feed & Search)', 80, 520, 140, 55, style_green)
    add_node('node_add_tab', 'Class\nAddPuppyTab\n(Media Picker)', 260, 520, 140, 55, style_green)
    add_node('node_fav_tab', 'Class\nFavoritesTab\n(Saved Posts)', 440, 520, 140, 55, style_green)
    add_node('node_profile_tab', 'Class\nProfileTab\n(Profile & Posts)', 620, 520, 140, 55, style_green)

    # 6. Secondary / Detail Screens (Bottom Row)
    add_node('node_details_screen', 'Class\nPuppyDetailsScreen', 170, 635, 155, 50, style_green)
    add_node('node_user_profile', 'Class\nUserProfileScreen', 350, 635, 150, 50, style_green)
    add_node('node_create_post', 'Class\nCreatePostScreen', 530, 635, 150, 50, style_green)
    add_node('node_notifications', 'Class\nNotificationsScreen', 710, 635, 150, 50, style_green)

    # Connections / Edges without labels
    add_edge('e1', 'node_main', 'node_splash')
    add_edge('e2', 'node_splash', 'node_auth_check')
    
    # Auth Decision branch
    add_edge('e3', 'node_auth_check', 'node_signin', label='NO')
    add_edge('e4', 'node_auth_check', 'node_main_screen', label='SI')

    # Auth Screens connection
    add_edge('e5', 'node_signin', 'node_signup')
    add_edge('e6', 'node_signin', 'node_firebase_auth')
    add_edge('e7', 'node_signup', 'node_firebase_auth')
    add_edge('e8', 'node_signin', 'node_main_screen')

    # MainScreen -> BottomNavBar
    add_edge('e9', 'node_main_screen', 'node_bottom_bar')

    # BottomNavBar -> Tabs (Cleaned, no Tab 0 / Tab 1 / Tab 2 / Tab 3 text)
    add_edge('e10', 'node_bottom_bar', 'node_home_tab')
    add_edge('e11', 'node_bottom_bar', 'node_add_tab')
    add_edge('e12', 'node_bottom_bar', 'node_fav_tab')
    add_edge('e13', 'node_bottom_bar', 'node_profile_tab')

    # Tabs -> Screens
    add_edge('e14', 'node_home_tab', 'node_details_screen')
    add_edge('e15', 'node_home_tab', 'node_user_profile')
    add_edge('e16', 'node_add_tab', 'node_create_post')
    add_edge('e17', 'node_fav_tab', 'node_details_screen')
    add_edge('e18', 'node_profile_tab', 'node_notifications')

    tree = ET.ElementTree(mxfile)
    ET.indent(tree, space="  ", level=0)
    return ET.tostring(mxfile, encoding='utf-8', method='xml').decode('utf-8')

xml_content = '<?xml version="1.0" encoding="UTF-8"?>\n' + create_nav_drawio_clean()

output_path_1 = '/Users/tareknaja/Desktop/Uni/Programmazione Mobile/paws_flutter/avvio_navigazione_flutter.drawio'
output_path_2 = '/Users/tareknaja/Desktop/Uni/Programmazione Mobile/Paws/TesinaPaws/avvio_navigazione_flutter.drawio'

with open(output_path_1, 'w', encoding='utf-8') as f:
    f.write(xml_content)

with open(output_path_2, 'w', encoding='utf-8') as f:
    f.write(xml_content)

print("Successfully removed Tab 0..Tab 3 labels from draw.io files.")

from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Permite peticiones desde cualquier origen

# Configuración de la base de datos
DATABASE = 'gamestore.db'

def init_db():
    """Inicializa la base de datos con las tablas necesarias"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    # Tabla de usuarios
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            password TEXT NOT NULL,
            favorites TEXT DEFAULT '[]'
        )
    ''')
    
    # Tabla de juegos
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            developer TEXT NOT NULL,
            imageLink TEXT,
            description TEXT,
            price REAL DEFAULT 0,
            unitsInStock INTEGER DEFAULT 0,
            platforms TEXT DEFAULT '[]',
            releaseDate TEXT,
            mediaCarousel TEXT DEFAULT '[]'
        )
    ''')
    
    conn.commit()
    conn.close()

def get_db_connection():
    """Obtiene conexión a la base de datos"""
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

def row_to_dict(row, table_type):
    """Convierte una fila de BD con el formato correcto"""
    result = dict(row)
    
    if table_type == 'users':
        # Convertir favorites de string JSON a lista
        if result.get('favorites'):
            try:
                result['favorites'] = json.loads(result['favorites'])
            except:
                result['favorites'] = []
        else:
            result['favorites'] = []
    
    elif table_type == 'games':
        # Convertir campos JSON de string a lista/objeto
        if result.get('platforms'):
            try:
                result['platforms'] = json.loads(result['platforms'])
            except:
                result['platforms'] = []
        else:
            result['platforms'] = []
            
        if result.get('mediaCarousel'):
            try:
                result['mediaCarousel'] = json.loads(result['mediaCarousel'])
            except:
                result['mediaCarousel'] = []
        else:
            result['mediaCarousel'] = []
    
    # Convertir ID a string para mantener compatibilidad
    result['id'] = str(result['id'])
    
    return result

# ================== RUTAS PARA USUARIOS ==================

@app.route('/users', methods=['GET'])
def get_users():
    """Obtiene todos los usuarios"""
    conn = get_db_connection()
    users = conn.execute('SELECT * FROM users ORDER BY id').fetchall()
    conn.close()
    
    return jsonify([row_to_dict(row, 'users') for row in users])

@app.route('/users/<user_id>', methods=['GET'])
def get_user(user_id):
    """Obtiene un usuario específico por ID"""
    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    conn.close()
    
    if user is None:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    
    return jsonify(row_to_dict(user, 'users'))

@app.route('/users', methods=['POST'])
def create_user():
    """Crea un nuevo usuario"""
    data = request.get_json()
    
    if not data or not data.get('name') or not data.get('password'):
        return jsonify({'error': 'Nombre y contraseña son requeridos'}), 400
    
    conn = get_db_connection()
    favorites_json = json.dumps(data.get('favorites', []))
    
    cursor = conn.execute(
        'INSERT INTO users (name, password, favorites) VALUES (?, ?, ?)',
        (data['name'], data['password'], favorites_json)
    )
    conn.commit()
    user_id = cursor.lastrowid
    conn.close()
    
    return jsonify({'mensaje': 'Usuario creado', 'id': str(user_id)}), 201

@app.route('/users/<user_id>', methods=['PUT'])
def update_user(user_id):
    """Actualiza un usuario existente"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'No se enviaron datos'}), 400
    
    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    
    if user is None:
        conn.close()
        return jsonify({'error': 'Usuario no encontrado'}), 404
    
    # Preparar datos para actualizar
    name = data.get('name', user['name'])
    password = data.get('password', user['password'])
    favorites = data.get('favorites')
    
    if favorites is not None:
        favorites_json = json.dumps(favorites)
    else:
        favorites_json = user['favorites']
    
    conn.execute(
        'UPDATE users SET name = ?, password = ?, favorites = ? WHERE id = ?',
        (name, password, favorites_json, user_id)
    )
    conn.commit()
    conn.close()
    
    return jsonify({'mensaje': 'Usuario actualizado'})

@app.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Elimina un usuario"""
    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    
    if user is None:
        conn.close()
        return jsonify({'error': 'Usuario no encontrado'}), 404
    
    conn.execute('DELETE FROM users WHERE id = ?', (user_id,))
    conn.commit()
    conn.close()
    
    return jsonify({'mensaje': 'Usuario eliminado'})

# ================== RUTAS PARA JUEGOS ==================

@app.route('/games', methods=['GET'])
def get_games():
    """Obtiene todos los juegos"""
    conn = get_db_connection()
    games = conn.execute('SELECT * FROM games ORDER BY id').fetchall()
    conn.close()
    
    return jsonify([row_to_dict(row, 'games') for row in games])

@app.route('/games/<game_id>', methods=['GET'])
def get_game(game_id):
    """Obtiene un juego específico por ID"""
    conn = get_db_connection()
    game = conn.execute('SELECT * FROM games WHERE id = ?', (game_id,)).fetchone()
    conn.close()
    
    if game is None:
        return jsonify({'error': 'Juego no encontrado'}), 404
    
    return jsonify(row_to_dict(game, 'games'))

@app.route('/games', methods=['POST'])
def create_game():
    """Crea un nuevo juego"""
    data = request.get_json()
    
    if not data or not data.get('name') or not data.get('developer'):
        return jsonify({'error': 'Nombre y desarrollador son requeridos'}), 400
    
    conn = get_db_connection()
    
    # Preparar datos JSON
    platforms_json = json.dumps(data.get('platforms', []))
    media_carousel_json = json.dumps(data.get('mediaCarousel', []))
    
    cursor = conn.execute('''
        INSERT INTO games (name, developer, imageLink, description, price, 
                          unitsInStock, platforms, releaseDate, mediaCarousel) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        data['name'],
        data['developer'],
        data.get('imageLink'),
        data.get('description'),
        data.get('price', 0),
        data.get('unitsInStock', 0),
        platforms_json,
        data.get('releaseDate'),
        media_carousel_json
    ))
    
    conn.commit()
    game_id = cursor.lastrowid
    conn.close()
    
    return jsonify({'mensaje': 'Juego creado', 'id': str(game_id)}), 201

@app.route('/games/<game_id>', methods=['PUT'])
def update_game(game_id):
    """Actualiza un juego existente"""
    data = request.get_json()
    
    if not data:
        return jsonify({'error': 'No se enviaron datos'}), 400
    
    conn = get_db_connection()
    game = conn.execute('SELECT * FROM games WHERE id = ?', (game_id,)).fetchone()
    
    if game is None:
        conn.close()
        return jsonify({'error': 'Juego no encontrado'}), 404
    
    # Preparar datos para actualizar
    name = data.get('name', game['name'])
    developer = data.get('developer', game['developer'])
    imageLink = data.get('imageLink', game['imageLink'])
    description = data.get('description', game['description'])
    price = data.get('price', game['price'])
    unitsInStock = data.get('unitsInStock', game['unitsInStock'])
    releaseDate = data.get('releaseDate', game['releaseDate'])
    
    # Manejar arrays JSON
    platforms = data.get('platforms')
    if platforms is not None:
        platforms_json = json.dumps(platforms)
    else:
        platforms_json = game['platforms']
    
    mediaCarousel = data.get('mediaCarousel')
    if mediaCarousel is not None:
        media_carousel_json = json.dumps(mediaCarousel)
    else:
        media_carousel_json = game['mediaCarousel']
    
    conn.execute('''
        UPDATE games SET name = ?, developer = ?, imageLink = ?, description = ?, 
                        price = ?, unitsInStock = ?, platforms = ?, releaseDate = ?, 
                        mediaCarousel = ? WHERE id = ?
    ''', (name, developer, imageLink, description, price, unitsInStock, 
          platforms_json, releaseDate, media_carousel_json, game_id))
    
    conn.commit()
    conn.close()
    
    return jsonify({'mensaje': 'Juego actualizado'})

@app.route('/games/<game_id>', methods=['DELETE'])
def delete_game(game_id):
    """Elimina un juego"""
    conn = get_db_connection()
    game = conn.execute('SELECT * FROM games WHERE id = ?', (game_id,)).fetchone()
    
    if game is None:
        conn.close()
        return jsonify({'error': 'Juego no encontrado'}), 404
    
    conn.execute('DELETE FROM games WHERE id = ?', (game_id,))
    conn.commit()
    conn.close()
    
    return jsonify({'mensaje': 'Juego eliminado'})

# ================== RUTAS ADICIONALES ==================

@app.route('/users/<user_id>/favorites', methods=['GET'])
def get_user_favorites(user_id):
    """Obtiene los juegos favoritos de un usuario"""
    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    
    if user is None:
        conn.close()
        return jsonify({'error': 'Usuario no encontrado'}), 404
    
    try:
        favorites = json.loads(user['favorites']) if user['favorites'] else []
    except:
        favorites = []
    
    if not favorites:
        conn.close()
        return jsonify([])
    
    # Obtener los juegos favoritos
    placeholders = ','.join(['?' for _ in favorites])
    games = conn.execute(f'SELECT * FROM games WHERE id IN ({placeholders})', favorites).fetchall()
    conn.close()
    
    return jsonify([row_to_dict(row, 'games') for row in games])

@app.route('/users/<user_id>/favorites/<game_id>', methods=['POST'])
def add_favorite(user_id, game_id):
    """Agrega un juego a favoritos del usuario"""
    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    
    if user is None:
        conn.close()
        return jsonify({'error': 'Usuario no encontrado'}), 404
    
    # Verificar que el juego existe
    game = conn.execute('SELECT * FROM games WHERE id = ?', (game_id,)).fetchone()
    if game is None:
        conn.close()
        return jsonify({'error': 'Juego no encontrado'}), 404
    
    try:
        favorites = json.loads(user['favorites']) if user['favorites'] else []
    except:
        favorites = []
    
    if game_id not in favorites:
        favorites.append(game_id)
        favorites_json = json.dumps(favorites)
        
        conn.execute('UPDATE users SET favorites = ? WHERE id = ?', (favorites_json, user_id))
        conn.commit()
    
    conn.close()
    return jsonify({'mensaje': 'Juego agregado a favoritos'})

@app.route('/users/<user_id>/favorites/<game_id>', methods=['DELETE'])
def remove_favorite(user_id, game_id):
    """Elimina un juego de favoritos del usuario"""
    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    
    if user is None:
        conn.close()
        return jsonify({'error': 'Usuario no encontrado'}), 404
    
    try:
        favorites = json.loads(user['favorites']) if user['favorites'] else []
    except:
        favorites = []
    
    if game_id in favorites:
        favorites.remove(game_id)
        favorites_json = json.dumps(favorites)
        
        conn.execute('UPDATE users SET favorites = ? WHERE id = ?', (favorites_json, user_id))
        conn.commit()
    
    conn.close()
    return jsonify({'mensaje': 'Juego eliminado de favoritos'})

# ================== MAIN ==================

@app.route('/', methods=['GET'])
def home():
    """Ruta de inicio con información de la API"""
    return jsonify({
        'mensaje': 'API de Tienda de Videojuegos',
        'endpoints': {
            'users': '/users',
            'games': '/games',
            'user_favorites': '/users/{id}/favorites'
        }
    })

if __name__ == '__main__':
    init_db()
    app.run(debug=True, host='0.0.0.0', port=5000)
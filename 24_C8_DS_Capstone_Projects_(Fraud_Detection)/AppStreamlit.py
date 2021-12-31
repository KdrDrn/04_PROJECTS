import streamlit as st
import pickle
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from PIL import Image
import base64
st.sidebar.title('Transaction Information')

html_temp = """
<div style="background-color:Blue;padding:10px">
<h2 style="color:white;text-align:center;">Fraud Detection</h2>
</div><br>"""


st.markdown(html_temp,unsafe_allow_html=True)
st.markdown("<h1 style='text-align: center; color: Black;'>Select Your Model</h1>", unsafe_allow_html=True)

selection = st.selectbox("", ["Logistic Regression","Random Forest"])



if selection =="Logistic Regression":
	st.write("You selected", selection, "model")
	model = pickle.load(open('logistic_regression_model', 'rb'))
else:
	st.write("You selected", selection, "model")
	model = pickle.load(open('random_forest_model', 'rb'))

v2 = st.sidebar.slider(label="V2-PCA", min_value=-10.00, max_value=15.00, step=0.01)
v3 = st.sidebar.slider(label="V3-PCA", min_value=-25.00, max_value=5.00, step=0.01)
v4 = st.sidebar.slider(label="V4-PCA", min_value=-5.00, max_value=15.00, step=0.01)
v7 = st.sidebar.slider(label="V7-PCA", min_value=-45.00, max_value=130.00, step=0.01)
v10 = st.sidebar.slider(label="V10-PCA", min_value=-20.00, max_value=5.00, step=0.01)
v11 = st.sidebar.slider(label="V11-PCA", min_value=-5.00, max_value=15.00, step=0.01)
v12 = st.sidebar.slider(label="V12-PCA", min_value=-20.00, max_value=5.00, step=0.01)
v14 = st.sidebar.slider(label="V14-PCA", min_value=-20.00, max_value=5.00, step=0.01)
v16 = st.sidebar.slider(label="V16-PCA", min_value=-15.00, max_value=20.00, step=0.01)
v17 = st.sidebar.slider(label="V17-PCA", min_value=-30.00, max_value=10.00, step=0.01)


coll_dict = {'V2-PCA':v2, 'V3-PCA':v3, 'V4-PCA':v4, 'V7-PCA':v7, 'V10-PCA':v10,\
			'V11-PCA':v11, 'V12-PCA':v12, 'V14-PCA':v14, 'V16-PCA':v16, 'V17-PCA':v17}

columns = ['v2', 'v3', 'v4', 'v7', 'v10', 'v11', 'v12', 'v14', 'v16', 'v17']

df_coll = pd.DataFrame.from_dict([coll_dict])
user_inputs = df_coll

prediction = model.predict(user_inputs)


html_temp = """
<div style="background-color:Black;padding:10px">
<h2 style="color:white;text-align:center;">Fraud Detection Prediction - Group - 4</h2>


</div><br>"""

st.markdown("<h1 style='text-align: center; color: Black;'>Transaction Information</h1>", unsafe_allow_html=True)

st.table(df_coll)

st.subheader('Click PREDICT if configuration is OK')

if st.button('PREDICT'):
	if prediction[0]==0:
		st.success(prediction[0])
		st.success(f'Transaction is SAFE :)')
	elif prediction[0]==1:
		st.warning(prediction[0])
		st.warning(f'ALARM! Transaction is FRAUDULENT :(')